-- fives
-- v1.0.0 @username
-- llllllll.co/t/mc101-grid
--
-- Grid control for MC-101
--
-- E1: Select track
-- E2: Select parameter
-- E3: Adjust value
--
-- Grid:
-- Each row controls a track
-- Buttons trigger clips

g = grid.connect()
midi_prog = midi.connect(midi_device)

-- state variables
selected_track = 1
tracks = 4 -- MC-101 has 4 tracks
active_clips = {1, 1, 1, 1} -- Store active clip for each track (1-based)
last_grid_event = "No grid events yet"
midi_device = 3 -- MIDI device number for program changes

function init()
  -- Add parameters
  params:add_number("midi_device", "MIDI Device", 1, 16, midi_device)
  params:set_action("midi_device", function(x)
    midi_device = x
    midi_prog = midi.connect(midi_device)
  end)
  
  -- Start screen redraw clock
  screen_redraw_clock = clock.run(function()
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)
  -- Start grid redraw clock
  grid_redraw_clock = clock.run(function()
    while true do
      clock.sleep(1/30)
      grid_redraw()
    end
  end)
end

-- Handle grid input
function g.key(x, y, z)
  if z == 1 then -- button pressed
    local track = y -- row number corresponds to track
    if track <= tracks then
      -- Send program change to trigger clip x on track y
      -- Track number (y) determines MIDI channel
      -- x-1 for 0-based program numbers (0-15)
      midi_prog:program_change(x - 1, track)
      -- Store which clip is active for this track
      active_clips[track] = x
      -- Store the event description
      last_grid_event = string.format("Track %d Clip %d", track, x)
    end
  end
end

-- Grid redraw function
function grid_redraw()
  g:all(0)
  -- Show active clips as bright (15), selected track row dim (4)
  for track = 1, tracks do
    for x = 1, 16 do
      if x == active_clips[track] then
        g:led(x, track, 15) -- Active clip is bright
      end
    end
  end
  g:refresh()
end


-- Cleanup on script close
function redraw()
  screen.clear()
  screen.move(0, 30)
  screen.text(last_grid_event)
  screen.move(0, 50)
  screen.text(string.format("MIDI Device: %d", midi_device))
  screen.update()
end

function cleanup()
  if grid_redraw_clock then
    clock.cancel(grid_redraw_clock)
  end
  if screen_redraw_clock then
    clock.cancel(screen_redraw_clock)
  end
end
