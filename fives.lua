-- fives
-- v1.0.0 @username
-- llllllll.co/t/mc101-grid
--
-- Grid control for MC-101
--
-- E1: MIDI device (1-4)
-- E2: Select device to edit (send/receive)
-- E3: Adjust selected device (1-4)
--
-- Grid:
-- Each row controls a track
-- Buttons trigger clips

g = grid.connect()
midi_prog = midi.connect(midi_device)
midi_in = midi.connect(4)

-- state variables
selected_track = 1
tracks = 4 -- MC-101 has 4 tracks
active_clips = {1, 1, 1, 1} -- Store active clip for each track (1-based)
last_grid_event = "No grid events yet"
midi_device = 1 -- MIDI device number for program changes
midi_in_device = 4 -- MIDI device number for receiving notes
selected_device = "send" -- which device we're editing with encoders
last_note_event = "No notes yet"

function init()
  -- Set up MIDI input handler
  midi_in.event = function(data)
    if data[1] >= 0x80 and data[1] <= 0x9F then -- note on/off on any channel
      local msg_type = (data[1] >= 0x90) and "note_on" or "note_off"
      last_note_event = string.format("%s note=%d vel=%d", msg_type, data[2], data[3])
      -- Pass through to MC-101
      midi_prog:send(data)
    end
  end
  
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


-- Handle encoder input
function enc(n, d)
  if n == 1 then
    midi_device = util.clamp(midi_device + d, 1, 4)
    midi_prog = midi.connect(midi_device)
  elseif n == 2 then
    selected_device = selected_device == "send" and "receive" or "send"
  elseif n == 3 then
    if selected_device == "send" then
      midi_device = util.clamp(midi_device + d, 1, 4)
      midi_prog = midi.connect(midi_device)
    else
      midi_in_device = util.clamp(midi_in_device + d, 1, 4)
      midi_in = midi.connect(midi_in_device)
    end
  end
end

function redraw()
  screen.clear()
  screen.move(0, 30)
  screen.text(string.format("MC 101 send %d: %s", midi_device, last_grid_event))
  screen.move(0, 40)
  screen.text(string.format("MIDI in %d: %s", midi_in_device, last_note_event))
  screen.move(0, 50)
  screen.text(string.format("Editing: %s device", selected_device))
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
