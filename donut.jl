hidecursor() = print("\e[?25l")
function clearscreen()
	# Move cursor to beginning, then clear to end then again begin
	#println("\x1b[42m")
	println("\33[H")
	println("\33[J")
	println("\33[H")
	hidecursor()
end

function norm(A::Array)
    s = 0
    for c in A
        s += c*c
    end
    sqrt(s)
end

function renderframe(width::Int64, height::Int64, A::Float64, B::Float64)
    #A::Float64 = 1 # Rotation angle around X-axis
    #B::Float64 = 1 # Rotation angle around Z-axis
    dtheta::Float64 = 0.1
    dphi::Float64 = 0.1

    # Rotational matrices
    cosA = cos(A); sinA = sin(A); cosB = cos(B); sinB = sin(B)
    rotX::Array{Float64} = [1 0 0;0 cosA sinA;0 -1*sinA cosA]
    rotZ::Array{Float64} = [cosB sinB 0;-1*sinB cosB 0;0 0 1]

    # Constants
    R1::Float64 = 1
    R2::Float64 = 2
    K2::Float64 = 5
    K1::Float64 = 25
    # 5, 500 
    #K1::Float64 = width*K2*3/(8*(R1+R2)) # how far is user away?
    zbuffer = zeros(width, height)
    output = fill(' ', (width, height))

    theta::Float64 = 0
    while(theta<2*pi)
        # Precalculate
        costheta::Float64 = cos(theta)
        sintheta::Float64 = sin(theta)

        circleco::Array{Float64, 2} = [R2+R1*costheta R1*sintheta 0]
        N::Array{Float64, 2} = [costheta sintheta 0] # Surface normal

        phi::Float64 = 0
        while(phi<2*pi)
            # Precalculate
            cosphi::Float64 = cos(phi)
            sinphi::Float64 = sin(phi)

            rotY::Array{Float64} = [cosphi 0 sinphi;0 1 0;-1*sinphi 0 cosphi]

            # Calculate the actual 3D coordinates
            co = circleco*rotY*rotX*rotZ
            x::Float64 = co[1]
            y::Float64 = co[2]
            z::Float64 = K2 + co[3] # move it back
            ooz::Float64 = 1/z

            # Project them onto screen, and put donut in middle
            # Only discrete vals, to be indexed
            xp::Int64 = round(Int64, (width/2+K1*ooz*x))
            yp::Int64 = round(Int64, (height/2-K1*ooz*y))
            if yp <= 0
                yp = 1
            elseif yp > height
                yp = height
            end
            if xp <= 0
                xp = 1
            elseif xp > width
                xp = width
            end
            # Calculate Luminance L; dot product rotated surface normal
            # and light vector from behind and above user. best: normalized vector, but then only values between 0 and 1. (compensate when choosing character to represent luminance index)
            # ie ligt vector = [0,5,-1], so way higher. norm = sqrt(26), so L values between 0 and sqrt(26) == +-5. If we want to choose out of 12 characters, we have to multiply it by 12/5 (max after rounding should be 12)
            # or L*12/norm
            lightvec::Array{Float64, 1} = [0;0;-1]
            normlightvec::Float64 = norm(lightvec)
            L::Float64 = (N*rotY*rotX*rotZ*lightvec)[1]
            if L>0
                if ooz>zbuffer[xp,yp]
                    zbuffer[xp,yp] = ooz
                    luminance_index::Int64 = floor(Int64, L*12/normlightvec)
                    output[xp, yp] = ".,-~:;=!*#%@"[abs(luminance_index)+1] # absolute value not necessary, only chosen if donut itself is doing the light (so light vector with z>0)
                end
            end
            phi += dphi
        end
        theta += dtheta
    end
    for j in 1:(height)
        for i in 1:(width)
            """
            if output[i, j] == ' '
                print("0")
            end
            """
            print(output[i, j])
        end
        print("\n")
    end
end

function renderframeoptimized(width::Int64, height::Int64, A::Float64, B::Float64)
    #A::Float64 = 1 # Rotation angle around X-axis
    #B::Float64 = 1 # Rotation angle around Z-axis
    dtheta::Float64 = 0.07
    dphi::Float64 = 0.04

    # Rotational matrices
    cosA = cos(A); sinA = sin(A); cosB = cos(B); sinB = sin(B)
    #rotX::Array{Float64} = [1 0 0;0 cosA sinA;0 -1*sinA cosA]
    #rotZ::Array{Float64} = [cosB sinB 0;-1*sinB cosB 0;0 0 1]

    # Constants
    R1::Float64 = 1
    R2::Float64 = 2
    K2::Float64 = 5
    K1::Float64 = width*K2*3/(8*(R1+R2)) #how far is user away?
    zbuffer = zeros(width, height)
    output = fill(' ', (width, height))

    theta::Float64 = 0
    while(theta<2*pi)
        # Precalculate
        costheta::Float64 = cos(theta)
        sintheta::Float64 = sin(theta)

        circlex::Float64 = R2+R1*costheta
        circley::Float64 = R1*sintheta
        N::Array{Float64, 2} = [costheta sintheta 0] # Surface normal

        phi::Float64 = 0
        while(phi<2*pi)
            # Precalculate
            cosphi::Float64 = cos(phi)
            sinphi::Float64 = sin(phi)

            # Calculate the actual 3D coordinates
            x::Float64 = circlex*(cosB*cosphi + sinA*sinB*sinphi) - circley*cosA*sinB
            y::Float64 = circlex*(sinB*cosphi - sinA*cosB*sinphi) + circley*cosA*cosB
            z::Float64 = K2 + cosA*circlex*sinphi + circley*sinA # move it back
            ooz::Float64 = 1/z

            # Project them onto screen, and put donut in middle
            # Only discrete vals, to be indexed
            xp::Int64 = round(Int64, (width/2+K1*ooz*x))
            yp::Int64 = round(Int64, (height/2-K1*ooz*y))
            if yp <= 0
                yp = 1
            elseif yp > height
                yp = height
            end
            if xp <= 0
                xp = 1
            elseif xp > width
                xp = width
            end
            # Calculate Luminance L; dot product rotated surface normal
            # and light vector from behind and above user.
            L::Float64 = cosphi*costheta*sinB - cosA*costheta*sinphi - sinA*sintheta + cosB*(cosA*sintheta-costheta*sinA*sinphi)
            if L>0
                if ooz>zbuffer[xp,yp]
                    zbuffer[xp,yp] = ooz
                    luminance_index::Int64 = round(Int64, L*8)
                    output[xp, yp] = ".,-~:;=!*#%@"[luminance_index+1]
                end
            end
            phi += dphi
        end
        theta += dtheta
    end
    for j in 1:(height)
        for i in 1:(width)
            """
            if output[i, j] == ' '
                print("0")
            end
            """
            print(output[i, j])
        end
        print("\n")
    end
end
function main()
    clearscreen()
    A::Float64 = 0;B::Float64 = 0 
    while true
        clearscreen()
        print("")
        renderframe(40, 40, A, B)
        A += 0.07
        B += 0.04
        sleep(0.01)
    end
end
main()