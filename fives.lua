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
midi_in = midi.connect(1)
midi_out = midi.connect(4)
midi_prog = midi.connect(3)  -- Additional connection for program changes

-- state variables
selected_track = 1
tracks = 4 -- MC-101 has 4 tracks
active_clips = {1, 1, 1, 1} -- Store active clip for each track (1-based)

function init()
  -- Set up midi device
  midi_in.event = midi_event
  
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

razzmatazz_notes = {
  kick = 36,
  snare = 37,
  hhc = 38,
  hho = 39,
  top1 = 40,
  top2 = 41,
  top3 = 42,
  top4 = 43,
}
mc_101_notes = {
  kick = 36,
  snare = 38, 
  hhc = 42,
  hho = 46,
  top1 = 41,
  top2 = 45,
  top3 = 48,
  top4 = 62,
}
-- Map MC-101 notes to Razzmatazz notes
function map_note(mc_note)
  for name, mc_val in pairs(mc_101_notes) do
    if mc_note == mc_val then
      return razzmatazz_notes[name]
    end
  end
  return mc_note -- if no mapping found, pass through unchanged
end

-- Handle incoming MIDI
function midi_event(data)
  if data[1] == 0x90 or data[1] == 0x80 then -- note on/off on channel 1
    
    local msg_type = (data[1] == 0x90) and "note_on" or "note_off"
    local mapped_note = map_note(data[2])
    print(string.format("MIDI: %s note=%d mapped_to=%d velocity=%d", 
                       msg_type, data[2], mapped_note, data[3]))
    local new_status = (data[1] & 0xF0) | 9 -- Change to channel 10
    midi_out:send({new_status, mapped_note, data[3]})
  end
end

-- Cleanup on script close
function cleanup()
  if grid_redraw_clock then
    clock.cancel(grid_redraw_clock)
  end
end
