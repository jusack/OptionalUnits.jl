using OptionalUnits
using Test
using Unitful

@testset "OptionalUnits.jl" begin
    @testset "BasicFunctions" begin
        @optionalunits function f1(a::Unitful.Length → u"m", b::Unitful.Length → u"mm")
            a + b
        end
        @test f1(1.0, 2.0) == 1.002u"m"
        @test f1(1, 2u"m") == 3u"m"
        @test f1(1, 2.0u"m") == 3.0u"m"
        @test f1(1u"mm", 2) == 3u"mm"
        @test f1(1u"km", 2u"km") == 3u"km"
        @test_throws MethodError f1(1u"m", 2u"m/s")
    end
    @testset "BasicFunctionsVectors" begin
        @optionalunits function f2(a::Vector{Unitful.Length → u"m"}, b::Unitful.Length → u"mm")
            a[1] += b
            return a
        end
        @test f2([1.0,2.0], 2.0) == [1.002u"m",2.0u"m"]
        @test f2([1,2], 2u"m") == [3u"m",2u"m"]
        @test f2([1,2], 2.0u"m") == [3.0u"m",2.0u"m"]
        @test f2([1u"mm",2u"mm"], 2) == [3u"mm",2u"mm"]
        @test f2([1,2]u"km", 2u"km") == [3u"km",2u"km"]
        @test_throws MethodError f2([1u"m",2], 3)
    end
    @testset "FunctionsWithDefaults" begin
        @optionalunits function f3(a::Unitful.Length → u"m", b::Unitful.Length → u"mm"=1u"mm")
            a + b
        end
        @test f3(1.0) == 1.001u"m"
        @test f3(1, 2u"m") == 3u"m"
        @test f3(1u"mm") == 2u"mm"
        @test f3(1u"km", 2u"km") == 3u"km"
        @test_throws MethodError f3(1u"m", 2u"m/s")
    end
    @testset "FunctionsWithDefaultsVector" begin
        @optionalunits function f4(a::Unitful.Length → u"m", b::Vector{Unitful.Length → u"mm"}=[1u"mm",2u"mm"])
            b[1] += a
            return b
        end
        @test f4(1) == [1001u"mm",2u"mm"]
        @test f4(1, [2u"m",3u"m"]) == [3u"m", 3u"m"]
        @test f4(1u"mm") == [2u"mm",2u"mm"]
        @test f4(1u"km", [2u"km", 4u"mm"]) == [3u"km",4u"mm"]
        @test_throws MethodError f4(1u"m", [2u"m",2u"m/s"])
    end
    @testset "Struct" begin
        @optionalunits struct Point
            x::typeof(1u"m")
            y::typeof(1.0u"mm")
            size::Int
        end

        @test Point(1,1,1)==Point(1u"m",1.0u"mm",1)
        @test Point(2u"m",5u"m",2)==Point(2u"m",5000.0u"mm",2)

        @test_throws InexactError Point(1u"mm",1,1)
        @test_throws InexactError Point(1.5,1,1)
    end
    @testset "StructVector" begin
        @optionalunits struct MyVector
            values::Vector{typeof(1.0u"mm")}
        end

        @test MyVector([1.0,1.0,1.0]).values==MyVector([1.0u"mm",1.0u"mm",1.0u"mm"]).values
        @test MyVector([2u"m",5u"m",2u"mm"]).values==MyVector([2000.0u"mm",5000.0u"mm",2.0u"mm"]).values

        @test_throws AssertionError MyVector([1u"mm",1,1])
    end
end
