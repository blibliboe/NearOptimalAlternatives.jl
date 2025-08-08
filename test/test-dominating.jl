@testset "Approximately Unique Solutions" begin
    @testset "Unique solution filter big treshold" begin
        # Sample input: 2D points
        solutions = [
            [1.0, 2.0],
            [1.05, 2.05],  # very close to the first one
            [3.0, 4.0],
            [3.01, 4.02],  # also close to the third one
            [10.0, 10.0]
        ]
        
        threshold = 0.1

        expected_unique = [
            [1.0, 2.0],
            [3.0, 4.0],
            [10.0, 10.0]
        ]

        result = approximately_unique_solutions(solutions; threshold = threshold)

        @test length(result) == length(expected_unique)

        for expected in expected_unique
            found = any(sol -> all(abs.(sol .- expected) .< 1e-8), result)
            @test found
        end
    end
    @testset "Unique solution small treshhold" begin
        # Sample input: 2D points
        solutions = [
            [1.0, 2.0],
            [1.05, 2.05],  # very close to the first one
            [3.0, 4.0],
            [2.99999, 4.000001],  # also close to the third one
            [10.0, 10.0]
        ]
        
        threshold = 1e-4

        expected_unique = [
            [1.0, 2.0],
            [1.05, 2.05],
            [3.0, 4.0],
            [10.0, 10.0]
        ]

        result = approximately_unique_solutions(solutions; threshold = threshold)

        @test length(result) == length(expected_unique)

        for expected in expected_unique
            found = any(sol -> all(abs.(sol .- expected) .< 1e-8), result)
            @test found
        end
    end
end
