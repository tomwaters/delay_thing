local dddelay = {
  max_taps = 3,
  num_taps = 1,
  beat_lengths = {0.1, 0.25, 0.5, 1, 1.5, 2, 4}
}

function dddelay.init()
  audio.level_cut(1.0)
  audio.level_adc_cut(0)
  
  for i=1, dddelay.max_taps do
  	softcut.loop_start(i, 1)
  	softcut.rec_level(i, 1)
    softcut.play(i, 1)
    softcut.loop(i, 1)
    softcut.rec(i, 1)

    softcut.position(i, 1)
    softcut.level(i, 0.9)
    
    softcut.level_input_cut(1, i, 1.0)
	  softcut.level_input_cut(2, i, 1.0)
	  
  	softcut.filter_dry(i, 0.075);
  	softcut.filter_fc(i, 1800);
  	softcut.filter_lp(i, 0.5);
  	softcut.filter_bp(i, 1.0);
  	softcut.filter_rq(i, 2.0);
  end
  
  dddelay.init_params()  
end

function dddelay.init_params()
  params:add{type = "number", id = "num_taps", name = "taps", min=1, max=3, default = 1, action=
    function(val)
      for i=2, dddelay.max_taps do
        if i > val then
          params:hide(i.."type")
          params:hide(i.."beats")
          params:hide(i.."length")
          params:hide(i.."feedback")
          params:hide(i.."pan")
        else
          params:show(i.."type")
          params:show(i.."length")
          params:show(i.."feedback")
          params:show(i.."pan")
          
          if params:show(i.."type") == 1 then
            params:show(i.."beats")
          else
            params:show(i.."length")
          end
        end
      end
      _menu.rebuild_params()
      
      dddelay.delay_update(val)
    end
  }
  
  for i=1, dddelay.max_taps do
    params:add_option(i.."type", i.." type", {'clocked', 'free'})
    params:set_action(i.."type", function(val) 
      if val == 1 then
        params:show(i.."beats")
        params:hide(i.."length")
      else
        params:show(i.."length")
        params:hide(i.."beats")
      end
      _menu.rebuild_params()

      dddelay.delay_param_change()
    end)
    
    params:add_option(i.."beats", i.." length", dddelay.beat_lengths)
    params:set_action(i.."beats", dddelay.delay_param_change)
    
    cs_LEN = controlspec.new(0, 5, 'lin', 0, 0.5, 'secs')
    params:add_control(i.."length", i.." length", cs_LEN)
    params:set_action(i.."length", dddelay.delay_param_change)
    
    cs_FEEDBACK = controlspec.new(0, 1, 'lin', 0, 0.55, '')
    params:add_control(i.."feedback", i.." feedback", cs_FEEDBACK)
    params:set_action(i.."feedback", dddelay.delay_param_change)
    
    params:add_control(i.."pan", i.." pan", controlspec.PAN)
    params:set_action(i.."pan", dddelay.delay_param_change)
  end
  
  params:default()
end

function dddelay.delay_param_change()
  dddelay.delay_update(dddelay.num_taps)
end

function dddelay.delay_update(taps)
  for i=1, dddelay.max_taps do
    if i > taps then
      softcut.enable(i, 0)
    else
      if i > dddelay.num_taps then
        softcut.position(i, 1)
      end
      
      softcut.enable(i, 1)
      softcut.rate(i, 1)
      softcut.voice_sync(1, i, 0)
      
      if params:get(i.."type") == 1 then
        softcut.loop_end(i, 1 + (60 / params:get("clock_tempo")) * dddelay.beat_lengths[params:get(i.."beats")])
      else
        softcut.loop_end(i, 1 + params:get(i.."length"))
      end
      
    	softcut.pre_level(i, params:get(i.."feedback"))
    	softcut.pan(i, params:get(i.."pan"))
    end
  end
  dddelay.num_taps = taps
end


return dddelay