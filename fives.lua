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
midi_out = midi.connect(3)

-- state variables
selected_track = 1
tracks = 4 -- MC-101 has 4 tracks
active_clips = {1, 1, 1, 1} -- Store active clip for each track (1-based)

function init()
  -- Set up midi device
  midi_out.event = midi_event
  
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
      midi_out:program_change(x - 1, track)
      -- Store which clip is active for this track
      active_clips[track] = x
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

-- Handle incoming MIDI
function midi_event(data)
  -- Add MIDI handling if needed
end

-- Cleanup on script close
function cleanup()
  if grid_redraw_clock then
    clock.cancel(grid_redraw_clock)
  end
end
