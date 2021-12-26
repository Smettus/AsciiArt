# other idea: watch video of the coding train
# problem of this implementation: lumanice values are only calculated with dot product of light vector
# and surface normal, not distance. For a plane, we need this distance in order to have different luminance icons 
# shown for different x,y,z values of the plane

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

function renderframe(width::Int64, height::Int64, A::Float64, B::Float64, C::Float64)
    dt::Float64 = 0.01
    dr::Float64 = 0.09
    dzed::Float64 = 0.01
    # Dimensions of plane
    W::Float64 = 5
    #H::Float64 = 10

    # Constants
    K2::Float64 = 2
    K1::Float64 = 5 # how far is user away? 

    cosA = cos(A); sinA = sin(A); cosB = cos(B); sinB = sin(B); cosC = cos(C); sinC = sin(C)
    rotX::Array{Float64} = [1 0 0;0 cosA sinA;0 -1*sinA cosA]
    rotY::Array{Float64} = [cosB 0 sinB;0 1 0;-1*sinB 0 cosB]
    rotZ::Array{Float64} = [cosC sinC 0;-1*sinC cosC 0;0 0 1]

    zbuffer = zeros(width,height)
    output = fill(' ', (width, height))

    # Begin with plane, perpendicular on z-axis
    r::Float64 = 0
    while(r<=W)
        t::Float64 = 0
        while(t <= 4)
            N::Array{Float64, 2} = [0 0 -1] # Normal

            # Parametrize the plane, for now only outer edge
            # Calculate 3D coordinates
            x::Float64 = 0
            y::Float64 = 0
            z::Float64 = K2 + 0
            ooz::Float64 = 1/z

            ogt = t # keep original t, but change under this (such that t becomes relative scaling factor, 0->1)
            # plane centered around origin
            if 0 <=t<= 1
                # right vertical edge
                y = r*t
                x = r
            elseif 1 <t<= 2
                # upper horizontal
                t=t-1
                x = r*t
                y = r
            elseif 2 <t<= 3
                # left vertical
                t=t-2
                y = r*t
                x = 0
            else
                # bottom horizontal
                t=t-3
                x = r*t
                y = 0
            end
            t = ogt # reset t
            co::Array{Float64, 2} = [x-r/2 y-r/2 z]*rotX*rotY*rotZ 
            # Account for neg values. Other option was to choose origin original co system at corner of the plane, but then the plane rotates around edge, not around y axis trough middle
            x = co[1]
            y = co[2]
            z = co[3]

            # Project onto plane
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
            
            # Calculate Luminance
            lightvec::Array{Float64,1} = [0;1;-1]
            normlightvec::Float64 = norm(lightvec)
            L = (N*rotX*rotY*rotZ*lightvec)[1] # dot product
            L = abs(L)
            if L>0
                if ooz>zbuffer[xp,yp]
                    zbuffer[xp,yp] = ooz
                    luminance_index::Int64 = floor(Int64, L*12/normlightvec)
                    output[xp, yp] = ".,-~:;=!*#%@"[luminance_index+1]
                end
            end
            t+=dt
        end
        r+=dr
    end
    for j in 1:(height)
        for i in 1:(width)
            if output[i,j] == ' '
                print(" ")
            else
                print(output[i, j])
            end
        end
        print("\n")
    end
end
function main()
    A::Float64 = 0; B::Float64 = 0; C::Float64 = 0
    
    while true
        clearscreen()
        renderframe(30,30, A, B, C)
        B+=0.07
        #sleep(0.5)
        #B+=0.07
    end
end
main()