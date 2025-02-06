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
      -- Send MIDI message to trigger clip x on track y
      -- MC-101 uses CC messages for clip triggering
      local cc_num = 40 + (track - 1) -- CC numbers 40-43 for tracks 1-4
      midi_out:cc(cc_num, x - 1, track) -- x-1 for 0-based clip numbers
    end
  end
end

-- Grid redraw function
function grid_redraw()
  g:all(0)
  -- Highlight current track row
  for x = 1, 16 do
    g:led(x, selected_track, 4)
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
