%% Planets
%% ESDL2 example for drawing circles without trigonometry
%% Build and run from project root: make planets
%% Feel free to copy and reuse as you wish.

-module(planets).
-export([run/0]).

run() ->
    spawn_opt(fun init/0, [{scheduler, 0}]).

init() ->
    %% setup sdl, window and renderer
    ok = sdl:start([video]),
    ok = sdl:stop_on_exit(),
    {ok, Window} = sdl_window:create("Planets", 10, 10, 500, 500, []),
    {ok, Renderer} = sdl_renderer:create(Window, -1, [accelerated, present_vsync]),

    %% clear screen (once ever in this example)
    ok = sdl_renderer:set_draw_color(Renderer, 0,0,0,0),
    ok = sdl_renderer:clear(Renderer),

    %% start animaton
    loop(#{window=>Window, renderer=>Renderer, t=>os:timestamp()}).

%% animation loop
loop(State) ->
    events_loop(),
    render(State),
    loop(State).

%% check for termination
events_loop() ->
    case sdl_events:poll() of
        false -> ok;
        #{type:=quit} -> terminate();
        _ -> events_loop()
    end.

%% render one frame
render(#{renderer:=Renderer, t:=TT}) ->
    T = timer:now_diff(os:timestamp(), TT) / 20000,
    ok = sdl_renderer:set_draw_color(Renderer, 0,0,0,0),
    ok = sdl_renderer:clear(Renderer),

    %% draw stars and planets
    draw_star(Renderer, T),
    draw_planet(Renderer,  7, 450, 1/600, T),
    draw_planet(Renderer,  3, 280, 1/300, T),
    draw_planet(Renderer,  3, 900, 1/300, T+70),
    draw_planet(Renderer,  5, 290, 1/200, T+100),
    draw_planet(Renderer, 12, 650, 1/700, T),

    %% render
    ok = sdl_renderer:present(Renderer).

terminate() ->
    init:stop(),
    exit(normal).

%% draw a star using wasteful and trigonometric circle math
draw_star(Renderer, T) ->
    ok = sdl_renderer:set_draw_color(Renderer, 255, 255, 255, 255),
    ok = sdl_renderer:draw_points(Renderer, circle(100, 250, 50, 120, T, 1)),
    ok = sdl_renderer:draw_points(Renderer, circle(100, 250, 53, 30, -T, 1)),
    ok = sdl_renderer:draw_points(Renderer, circle(100, 250, 45, 300, T/100, 1)).

%% get points for wasteful but sparkling circle, using trigonometric math
%% T effects a slow ant crawl of the dashed circle line when N is small enough
%% in relation to R. S gives a breathing effect of the size, scaling the entire
%% radius.
circle(X, Y, R, N, T, S) ->
    R1 = S * (R + math:cos(T/20)), %% radius
    D = math:pi() * 2 / N,
    [ #{x => X + erlang:round(R1 * math:cos((TT+T/30)/D)),
            y => Y + erlang:round(R1 * math:sin((TT+T/30)/D))}
    ||  TT <- lists:seq(1, N)].

%% draw a planet using fast, non-trigonometric circle math
%% R radius, O orbit distance, D relative speed, T frame.
draw_planet(Renderer, R, O, D, T) ->
    X = 100 + O * math:cos(T * D),
    Y = 250 + O * math:sin(T * D) / 5,
    ok = sdl_renderer:set_draw_color(Renderer, 255, 255, 255, 255),
    ok = draw_circle(Renderer, X, Y, R).

%% draw a circle using fast, non-trigonometric circle math
%%
%% Adaption from The Game Programming Wiki, SDL Tutorials:
%% http://content.gpwiki.org/index.php/SDL:Tutorials:Drawing_and_Filling_Circles
%%
%% "This is an implementation of the Midpoint Circle Algorithm
%% found on Wikipedia at the following link:
%% http://en.wikipedia.org/wiki/Midpoint_circle_algorithm"
%%
draw_circle(Renderer, NCX, NCY, R) when R > 0 ->

    %% The first pixel in the screen is represented by (0,0) in sdl,
    %% so remember that the beginning of the circle is not in the
    %% middle of the pixel but to the left-top from it:
    Error = - R,
    X = R - 0.5,
    Y = 0.5,
    CX = NCX - 0.5,
    CY = NCY - 0.5,

    %% calculate points and render
    sdl_renderer:draw_points(Renderer, circle_points([], CX, CY, X, Y, Error)).

%% get points of a circle using fast, non-trigonometric math
circle_points(L, CX, CY, X, Y) ->

   [#{x => erlang:round(CX + X), y => erlang:round(CY + Y)},
    #{x => erlang:round(CX + Y), y => erlang:round(CY + X)}
    | L].

%% get points of a circle using fast, non-trigonometric math
circle_points(L, CX, CY, X, Y, Error) when Error >= 0 ->
    circle_points(L, CX, CY, X - 1, Y, Error - X - X + 2);

circle_points(L, CX, CY, X, Y, Error) when X >= Y ->

   L1 = circle_points(L, CX, CY, X, Y),

   L2 = if
           X > 0 ->
               circle_points(L1, CX, CY, -X, Y);
           true ->
               L1
       end,

   L3 = if
           Y > 0 ->
               circle_points(L2, CX, CY, X, -Y);
           true ->
               L2
       end,

   L4 = if
           X > 0, Y > 0 ->
               circle_points(L3, CX, CY, -X, -Y);
           true ->
               L3
       end,

   circle_points(L4, CX, CY, X, Y + 1, Error + Y + Y + 1);

circle_points(L, _, _, _, _, _) -> L.
