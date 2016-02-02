facts("Element testing") do

context("spring") do
    @fact spring1e(3.0) --> [3.0 -3.0; -3.0 3.0]
    @fact spring1s(3.0, [3.0, 1.0]) --> 3.0 * (1.0 - 3.0)
end

context("plani4e") do
    K, f = plani4e([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem =
  1e11*[1.367692307692308   0.067307692307692  -1.012307692307693   0.740384615384616   0.059230769230770  -0.740384615384616  -0.414615384615385  -0.067307692307692;
   0.067307692307692   2.121538461538462   0.336538461538462   0.576153846153845  -0.740384615384616   0.449615384615385   0.336538461538462  -3.147307692307693;
  -1.012307692307693   0.336538461538462   4.340000000000000  -2.759615384615385  -0.414615384615385   0.336538461538462  -2.913076923076923   2.086538461538462;
   0.740384615384616   0.576153846153845  -2.759615384615385   8.163076923076922  -0.067307692307692  -3.147307692307692   2.086538461538461  -5.591923076923075;
   0.059230769230770  -0.740384615384616  -0.414615384615385  -0.067307692307692   1.367692307692308   0.067307692307692  -1.012307692307693   0.740384615384616;
  -0.740384615384616   0.449615384615385   0.336538461538462  -3.147307692307692   0.067307692307692   2.121538461538462   0.336538461538462   0.576153846153845;
  -0.414615384615385   0.336538461538462  -2.913076923076923   2.086538461538461  -1.012307692307693   0.336538461538462   4.340000000000000  -2.759615384615385;
  -0.067307692307692  -3.147307692307693   2.086538461538462  -5.591923076923075   0.740384615384616   0.576153846153845  -2.759615384615385   8.163076923076924]

   f_calfem =
  [0.250;
   0.625;
   0.250;
   0.625;
   0.250;
   0.625;
   0.250;
   0.625]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-15)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-15)


    # Patch test the element:
    # Set up a 4 element patch:
    # 17,18---15,16----13,14
    #   |       |        |
    #  7,8-----5,6-----11,12
    #   |       |        |
    #  1,2-----3,4------9,10
    # Set dirichlet boundary conditions such that u_x = u_y = 0.1x + 0.05y
    # Solve and see that middle node is at correct position
    function patch_test()
        Coord = [0 0
                 1 0
                 1 1
                 0 1
                 2 0
                 2 1
                 2 2
                 1 2
                 0 2]'

        Dof = [1 2
               3 4
               5 6
               7 8
               9 10
               11 12
               13 14
               15 16
               17 18]'

        Edof = [1 2 3 4 5 6 7 8;
                3 4 9 10 11 12 5 6;
                5 6 11 12 13 14 15 16;
                7 8 5 6 15 16 17 18]'

        function get_coord(dof)
          node = div(dof+1, 2)
          if dof % 2 == 0
              return Coord[2, node]
          else
              return Coord[1, node]
          end
        end

        ux = 0.1
        uy = 0.05
        bc_dofs = [1, 2, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 7, 8]
        bc = zeros(length(bc_dofs), 2)
        for i in 1:size(bc, 1)
          dof = bc_dofs[i]
          node = div(dof+1, 2)
          coord = Coord[:, node]
          bc[i, 1] = dof
          bc[i, 2] = ux * coord[1] + uy * coord[2]
        end

          a = start_assemble()
          D = hooke(2, 250e9, 0.3)
          for e in 1:size(Edof, 2)
            ex = [get_coord(i) for i in Edof[1:2:end, e]]
            ey = [get_coord(i) for i in Edof[2:2:end, e]]
            Ke, _ = plani4e(ex, ey, [2, 1, 2], D)
            assemble(Edof[:, e], a, Ke)
          end
          K = end_assemble(a)
          a, _ = solveq(K, zeros(18), bc)
          d_free = setdiff(collect(1:18), convert(Vector{Int}, bc[:,1]))
          @fact a[d_free] --> roughly([ux + uy, ux + uy])
      end
      patch_test()

end

context("plani4s/f") do
    σ, ε, eci = plani4s([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], hooke(2, 210e9, 0.3), collect(1:8))
    intf = plani4f([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], σ)

    σ_calfem = 1e12 * [
         0.917959456214025   2.506034396684739   1.027198155869629   0.684798770579753;
         0.619513778602157   1.312251686237266   0.579529639451827   0.386353092967885;
         0.414332375243997   2.823132929147349   0.971239591317404   0.647493060878269;
         0.115886697632129   1.629350218699876   0.523571074899601   0.349047383266401]

    ε_calfem = [
       -0.676239569296599   9.154700538379252                   0   8.478460969082654;
        0.247520861406803   4.535898384862244                   0   4.783419246269046;
       -3.447520861406804  11.464101615137755                   0   8.016580753730954;
       -2.523760430703402   6.845299461620747                   0   4.321539030917345]

    intf_calfem = 1e12 *
                  [-0.616000000000000;
                   -1.620230769230769;
                   -0.211076923076923;
                   -2.308384615384614;
                    0.314461538461538;
                    0.861000000000000;
                    0.512615384615385;
                    3.067615384615385]


    # correct for calfems order of gauss points
    @fact norm(σ - σ_calfem[[4,2,3,1], :]') / norm(σ_calfem) --> roughly(0.0, atol=1e-14)
    @fact norm(ε - ε_calfem[[4,2,3,1], :]') / norm(ε_calfem) --> roughly(0.0, atol=1e-14)
    @fact norm(intf - intf_calfem) / norm(intf_calfem) --> roughly(0.0, atol=1e-14)


end

context("plante") do
    K, f = plante([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 2, 1], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem = 1e12 * [
    0.243923076923077  -0.121153846153846  -0.392538461538462   0.282692307692308   0.148615384615385  -0.161538461538462
    -0.121153846153846   0.199500000000000   0.242307692307692  -0.501576923076923  -0.121153846153846   0.302076923076923
    -0.392538461538462   0.242307692307692   0.725307692307692  -0.484615384615385  -0.332769230769231   0.242307692307692
    0.282692307692308  -0.501576923076923  -0.484615384615385   1.375499999999999   0.201923076923077  -0.873923076923076
    0.148615384615385  -0.121153846153846  -0.332769230769231   0.201923076923077   0.184153846153846  -0.080769230769231
    -0.161538461538462   0.302076923076923   0.242307692307692  -0.873923076923076  -0.080769230769231   0.5718461538461549
    ]

    f_calfem = [1/6, 5/12, 1/6, 5/12, 1/6, 5/12]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)

end

context("plants/f") do
    σ, ε, eci = plants([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 2, 1], hooke(2, 210e9, 0.3), collect(1:6))
    intf = plantf([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 2, 1], σ)

    σ_calfem = 1e11 * [6.946153846153847   7.592307692307693   4.361538461538463   2.907692307692308]
    ε_calfem = [1.6   2. 0.   3.6]

    intf_calfem = 1e11 *
    [-2.713846153846155;
      2.051538461538461;
      1.195384615384617;
     -9.062307692307689;
      1.518461538461538;
      7.010769230769229]


    @fact norm(σ - σ_calfem') / norm(σ_calfem') --> roughly(0.0, atol=1e-14)
    @fact norm(ε - ε_calfem') / norm(ε_calfem') --> roughly(0.0, atol=1e-14)
    @fact norm(intf - intf_calfem) / norm(intf_calfem) --> roughly(0.0, atol=1e-14)

end

context("soli8e") do
    K, f = soli8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8], [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                  [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8], [2], hooke(4, 210e9, 0.3), [1.0, 2.5, 3.5])

    K_calfem_trace =  -1.469957313088530e+12

    f_calfem =    [-0.111944444444444,
                  -0.279861111111111,
                  -0.391805555555555,
                  -0.103472222222222,
                  -0.258680555555556,
                  -0.362152777777778,
                  -0.094583333333333,
                  -0.236458333333333,
                  -0.331041666666667,
                  -0.103333333333333,
                  -0.258333333333333,
                  -0.361666666666667,
                  -0.115416666666667,
                  -0.288541666666667,
                  -0.403958333333333,
                  -0.106666666666667,
                  -0.266666666666667,
                  -0.373333333333333,
                  -0.097777777777778,
                  -0.244444444444444,
                  -0.342222222222222,
                  -0.106805555555556,
                  -0.267013888888889,
                  -0.373819444444444]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("soli8s/f") do

    σ, ε, eci = soli8s([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                  [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                   [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8],
                   [2], hooke(4, 210e9, 0.3), collect(1:24))

    intf = soli8f([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                  [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                   [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8],
                   [2], σ)


   σ_calfem  = 1e12 *
   [ 3.1304    4.9422    4.1954    1.2052    0.8318    1.7377;
     3.0304    5.0756    3.5476    1.3637    0.5997    1.6223;
     2.2130    5.4923    3.6272    1.2375    0.3049    1.9445;
     2.3943    5.1671    4.2981    1.0439    0.6094    1.9958;
     3.1131    4.9475    4.1978    1.2014    0.8266    1.7438;
     3.0118    5.0851    3.5494    1.3608    0.5930    1.6297;
     2.2386    5.4792    3.6247    1.2414    0.3142    1.9344;
     2.4168    5.1603    4.2950    1.0488    0.6162    1.9879]

    ε_calfem = [
    1.8528   13.0689    8.4460   14.9217   10.2988   21.5149;
    2.1116   14.7725    5.3133   16.8841    7.4249   20.0858;
   -2.4898   17.8106    6.2647   15.3209    3.7749   24.0754;
   -2.1203   15.0448    9.6651   12.9245    7.5448   24.7099;
    1.7596   13.1152    8.4746   14.8748   10.2342   21.5898;
    2.0068   14.8417    5.3349   16.8485    7.3417   20.1767;
   -2.3453   17.7152    6.2349   15.3699    3.8896   23.9501;
   -1.9991   14.9845    9.6279   12.9855    7.6288   24.6124]

    intf_calfem = 1.0e+12 *
  [0.856819628833591;
   1.119194029953625;
   1.018859159182371;
   0.005378803073279;
   1.856876001955491;
   1.370915715348823;
   0.092253444463382;
   2.397119633012198;
   0.661044186752497;
   0.725661083349805;
   1.513082116130261;
   0.092244738856097;
  -0.092871486532213;
  -2.463972778060813;
  -0.663699749411605;
  -0.922901443556254;
  -1.546638265669111;
  -0.035100463720916;
  -0.645297909004294;
  -0.917551251877004;
  -0.805154733866490;
  -0.019042120627297;
  -1.958109485444647;
  -1.639108853140777]

    @fact norm(σ - σ_calfem[[1,5,4,8,2,6,3,7], [1,2,3,6,5,4]]') / norm(σ_calfem) --> roughly(0.0, atol=1e-5)
    @fact norm(ε - ε_calfem[[1,5,4,8,2,6,3,7], [1,2,3,6,5,4]]') / norm(ε_calfem) --> roughly(0.0, atol=1e-5)
    @fact norm(intf - intf_calfem) / norm(intf_calfem) --> roughly(0.0, atol=1e-14)
end

context("plani8e") do
    K, f = plani8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                   [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0], [2,2,2], hooke(2, 210e9, 0.3), [1.0, 2.5])

    K_calfem_trace =  -2.642786509138767e+11

    f_calfem =    [-0.218148148148149,
                   -0.545370370370372,
                    0.461111111111112,
                    1.152777777777779,
                    0.107037037037037,
                    0.267592592592593,
                   -0.207777777777778,
                   -0.519444444444446,
                    0.201481481481482,
                    0.503703703703705,
                    0.851851851851853,
                    2.129629629629632,
                   -0.485925925925926,
                   -1.214814814814815,
                   -1.136296296296297,
                   -2.840740740740743]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("plani8s/f") do
    σ, ε, eci = plani8s([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                    [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                    [2,2,2], hooke(2, 210e9, 0.3), collect(1:16))

    intf = plani8f([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                    [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                    [2,2,2], σ)

    σ_calfem  = 1e12 *
       [3.650145022337517   1.434616574500157   1.525428479051302   1.016952319367535;
        2.201097107658275   4.063281658184515   1.879313629752837   1.252875753168558;
        0.440420210981091   3.383114580081845   1.147060437318881   0.764706958212587;
        4.312622092875714   3.756926305287927   2.420864519449093   1.613909679632728]

    ε_calfem =
    [ 13.153007172724191  -0.562168932935663                   0  12.590838239788528;
        1.991992958462234  13.519802080767532                   0  15.511795039229769;
       -4.374439496376793  13.842239931389777                   0   9.467800435012986;
       11.710880216450519   8.270858674240404                   0  19.981738890690920]

    intf_calfem = 1e12 *
          [2.218465464202876;
           0.943335135731768;
          -1.641358230837728;
          -6.205387072491738;
          -1.414786066922642;
          -2.348005317622662;
           0.219317192904909;
           2.753296118678850;
           0.299337972462602;
           0.233522174093922;
          -3.456369551355917;
           0.030563354756790;
           7.238969169705642;
           6.149590932469637;
          -3.463575950159742;
          -1.556915325616566]


      @fact norm(σ - σ_calfem[[1,3, 2, 4], :]') / norm(σ_calfem) --> roughly(0.0, atol =1e-13)
      @fact norm(ε - ε_calfem[[1,3, 2, 4], :]') / norm(ε_calfem) --> roughly(0.0, atol=1e-13)
      @fact norm(intf - intf_calfem) / norm(intf_calfem) --> roughly(0.0, atol=1e-14)
end

context("flw2i4e") do
    K, f = flw2i4e([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], [1 2; 3 4], [2.0])

    K_calfem = [3.126666666666666   1.713333333333333  -1.193333333333333  -3.646666666666667;
                2.713333333333332   4.606666666666666  -4.646666666666666  -2.673333333333332;
               -1.193333333333333  -3.646666666666666   3.126666666666667   1.713333333333332;
               -4.646666666666667  -2.673333333333332   2.713333333333331   4.606666666666667]

    f_calfem = 0.5 * ones(4)

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)
end

context("flw2i4s") do
    es, et, eci  = flw2i4s([0, 1, 1.5, 0.5], [0.0, 0.2, 0.8, 0.6], [2, 2, 2], [1 2; 3 4], collect(1:4))

    es_calfem =
    [-8.816580753730953 -17.295041722813608;
     -4.659658815565644  -9.443078061834690;
     -9.740341184434355 -17.756921938165302;
     -5.583419246269046  -9.904958277186392]

    et_calfem =
    [-0.338119784648299   4.577350269189626;
      0.123760430703402   2.267949192431122;
     -1.723760430703402   5.732050807568878;
     -1.261880215351701   3.422649730810373]

      @fact norm(es - es_calfem[[4,2, 3, 1], :]') / norm(es_calfem) --> roughly(0.0, atol =1e-13)
      @fact norm(et - et_calfem[[4,2, 3, 1], :]') / norm(et_calfem) --> roughly(0.0, atol=1e-13)
end

context("flw2i8e") do
    K, f = flw2i8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                   [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0], [2,2], [1 2; 3 4], [3.0])

    K_calfem_trace = -7.239044777988562

    f_calfem =    [ -0.654444444444446;
                     1.383333333333335;
                     0.321111111111111;
                    -0.623333333333334;
                     0.604444444444445;
                     2.555555555555558;
                    -1.457777777777777;
                    -3.408888888888892]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("flw2i8s") do
    es, et, eci  = flw2i8s([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
                      [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                      [2,2], [1 2; 3 4], collect(1:8))

    es_calfem =
     [-6.014334653426435 -18.605172893214963;
     -14.515798559998650 -30.027593599228421;
     -11.655020183201380 -21.122820618214369;
     -14.126298782465668 -34.108037673156602]

     et_calfem =
   [6.576503586362095  -0.281084466467831;
   0.995996479231118   6.759901040383766;
  -2.187219748188395   6.921119965694889;
   5.855440108225263   4.135429337120202]

    @fact norm(es - es_calfem[[1 ,3, 2, 4], :]') / norm(es_calfem) --> roughly(0.0, atol =1e-13)
    @fact norm(et - et_calfem[[1 ,3, 2, 4], :]') / norm(et_calfem) --> roughly(0.0, atol=1e-13)
end


context("flw2te") do
    K, f = flw2te([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 1], [1 2; 3 4], [2.0])

    K_calfem =
    [-0.28  -0.96   1.24;
      0.04   7.28  -7.32;
      0.24  -6.32   6.08]

    f_calfem = [0.333333333333333;
                0.333333333333333;
                0.333333333333333]

    @fact norm(K - K_calfem) / norm(K) --> roughly(0.0, atol=1e-13)
    @fact norm(f - f_calfem) / norm(f) --> roughly(0.0, atol=1e-13)
end

context("flw2ts") do
    es, et, eci = flw2ts([0, 1, 1.5], [0.0, 0.2, 0.8], [2, 1], [1 2; 3 4], collect(1:3))

    es_calfem = [-2.8 -6.4;]
    et_calfem = [0.8 1.0;]

    @fact norm(es - es_calfem') / norm(es_calfem) --> roughly(0.0, atol =1e-13)
    @fact norm(et - et_calfem') / norm(et_calfem) --> roughly(0.0, atol=1e-13)
end


context("flw3i8e") do
    K, f = flw3i8e([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8], [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
                   [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8], [2], [1 2 3; 4 5 6; 7 8 9], [2.0])

    K_calfem_trace = -13.061465948339601

    f_calfem =    [ -0.223888888888889;
                    -0.206944444444444;
                    -0.189166666666667;
                    -0.206666666666667;
                    -0.230833333333333;
                    -0.213333333333333;
                    -0.195555555555556;
                    -0.213611111111111;]

    @fact trace(K) --> roughly(K_calfem_trace)
    @fact norm(f- f_calfem) / norm(f_calfem) --> roughly(0.0, atol =1e-13)
end

context("flw3i8s") do
    es, et, eci = flw3i8s([0.1, 1.2, 1.3, 0.4, 0.5, 1.7, 1.8, 0.8],
            [0.7, 0.6, 0.5, 0.4, 1.3, 1.2, 1.1, 1.0],
             [0.1, 0.2, 1.3, 1.4, 0.5, 0.6, 1.7, 1.8],
             [2], [1 2 3; 4 5 6; 7 8 9], collect(1:8))

    es_calfem =
    [-17.776175160614699 -41.143855440901305 -64.511535721187911;
     -15.865471228385472 -38.062870421610576 -60.260269614835671;
     -17.308566610251745 -38.894155304835266 -60.479743999418808;
     -18.988181979771785 -41.577794593367216 -64.167407206962665;
     -17.804610627736864 -41.154036293276000 -64.503461958815137;
     -15.898353572421859 -38.081812063213704 -60.265270554005554;
     -17.263255746778995 -38.868054302556374 -60.472852858333752;
     -18.951213939138484 -41.564558793067121 -64.177903646995730]

     et_calfem =
    [0.617608318633579   4.356288482404747   2.815329959057208;
     0.703880261901668   4.924167441036296   1.771085361470404;
    -0.829928772992190   5.936879630316172   2.088245374203863;
    -0.706752400887792   5.014935435599240   3.221687836487032;
     0.586536863339268   4.371741311123733   2.824863714050044;
     0.668930918285674   4.947243081798642   1.778312163512967;
    -0.781769647374687   5.905082103747760   2.078287062219387;
    -0.666357396405506   4.994845707601153   3.209293306780562]

    @fact norm(es - es_calfem[[1,5,4,8,2,6,3,7], :]') / norm(es_calfem) --> roughly(0.0, atol =1e-13)
    @fact norm(et - et_calfem[[1,5,4,8,2,6,3,7], :]') / norm(et_calfem) --> roughly(0.0, atol=1e-13)
end



context("bar") do
    # From example 3.2 in the book Strukturmekanik
    ex = [0.,  1.6]; ey = [0., -1.2]
    elem_prop = [200.e9, 1.0e-3]
    Ke = bar2e(ex, ey, elem_prop)
    ed = [0., 0., -0.3979 ,-1.1523]*1e-3
    N = bar2s(ex, ey, elem_prop, ed)
    Ke_ref = [ 64  -48. -64  48
              -48   36   48 -36
              -64   48   64 -48
               48  -36  -48  36]*1e6
    N_ref = 37.306e3
    @fact norm(Ke - Ke_ref) / norm(Ke_ref) --> roughly(0.0, atol=1e-15)
    @fact abs(N - N_ref) / N_ref --> roughly(0.0, atol=1e-15)

    Ke_g_ref = 1e7 *
    [ 6.400671507999999  -4.799104656000000  -6.400671507999999   4.799104656000000
     -4.799104656000000   3.601193792000000   4.799104656000000  -3.601193792000000
     -6.400671507999999   4.799104656000000   6.400671507999999  -4.799104656000000
      4.799104656000000  -3.601193792000000  -4.799104656000000   3.601193792000000]

    Ke_g = bar2g(ex, ey, elem_prop, N)

    @fact norm(Ke_g - Ke_g_ref) / norm(Ke_ref) --> roughly(0.0, atol=1e-15)

end

end
