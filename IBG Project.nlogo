breed [ individuals individual ]
breed [ indicators indicator ]
individuals-own [
  conformity 
  preparedness
  patience
  waiting-time
  switched-lane?                                             ;To check whether the agent has already switched to a less crowded lane
  pass-gantry?
]
patches-own [ busy? ]                                        ;Patch Variable:busy? - to check whether the patch is occupied

globals [
  tick-to-arrival 
  gantries                                                   ;A patch-set of all the gantries 
  green-gantries                                             ;A patch-set of all the green gantries (allowed to enter)
  red-gantries                                               ;A patch-set of all the red gantries (not allowed to enter)
  individual-spawn                                           ;A patch-set of spawning points for individuals
  individual-die                                             ;Patch set of individual-die points where individuals can leave the model
  individual-radius                                          ;Radius to locate the nearest empty gantry or the nearest gantry with the shortest queue
  error1-time                                                ;error 1 - the error that occurs when an individual steps into the gantry before the other person has fully crossed the gantry zone
  error1-rate                                                ;error 1 - occurance rate
  error2-time                                                ;error 2 - the shorter beep error
  error2-rate                                                ;error 2 - occurance rate
  error3-time                                                ;error 3 - the longer beep error
  error3-rate                                                ;error 3 - occurance rate
  
]

to setup
  ca
  reset-ticks
  resize-my-world
  setup-patches
  if signs
  [ setup-signs ]
  setup-locations
end

to resize-my-world
  ask patches [ set pcolor white ]
  let negative-value no-of-gantries - no-of-gantries - no-of-gantries
  resize-world negative-value no-of-gantries -10 11
end

to go
  spawn-individual
  move
  tick
end

to setup-individual
  set shape "person"
  ifelse (pycor > 0 )
  [set color blue set heading 180 ]                 ;top part is blue
  [set color violet set heading 0 ]                 ;bottom part is violet
  set xcor (ceiling xcor)
  set ycor (ceiling ycor)
  set switched-lane? false
  set pass-gantry? false
  set conformity random-float 1
  set preparedness random-float 1
  set patience random-float 1
end

to setup-signs
  ifelse direction = "unidirection"
  [
    ask patches with [pcolor = green ][ sprout-indicators 1 [set shape "arrow" set color white set size 0.5]]
    ask patches with [pcolor = red] [sprout-indicators 1 [set shape "x" set color white set size 0.5]]
  ]
  [
    ask patches with [pcolor = green and pycor = 0 and pxcor < -1 ] [ sprout-indicators 1 [set shape "arrow" set color white set size 0.5]]
    ask patches with [pcolor = green and pycor = 1 and pxcor > 1 ] [ sprout-indicators 1 [set shape "arrow" set color white set size 0.5]]
    ask patches with [pcolor = green and pycor = 1 and pxcor < -1 ] [ sprout-indicators 1 [set shape "x" set color white set size 0.5]]
    ask patches with [pcolor = green and pycor = 0 and pxcor > 1 ] [ sprout-indicators 1 [set shape "x" set color white set size 0.5]]
  ]
  ask indicators with [pxcor < 0 and pycor = 0] [set heading 0]
  ask indicators with [pxcor < 0 and pycor = 1] [set heading 180]
  ask indicators with [pxcor > 0 and pycor = 0] [set heading 0]
  ask indicators with [pxcor > 0 and pycor = 1] [set heading 180]
end



to setup-patches
  ; all patches white
  ask patches [ set pcolor white ]
  ;create gantry zone
  ask patches with [pycor = 0 or pycor = 1] [set pcolor grey]
  ;create sensing zone
  ask patches with [pycor > 6 or pycor < -5] [set pcolor yellow]
  ;ask patches [ set plabel pycor ]
  
  ;Set the centre patches black
  ask patches with [pxcor = 1 or pxcor = -1 or pxcor = 0 and (pycor <= 1 and pycor >= 0)][set pcolor black]
  
  ;Set up gantries on both sides
  ;red - not allowed to enter, green - allowed to enter
  
  ; unidirectional gantries
  ifelse direction = "unidirection"[
    ask patches with [pxcor mod 2 = 0 and pxcor > 0 and pxcor <= no-of-gantries and pycor = 0] [set pcolor red]
    ask patches with [pxcor mod 2 = 0 and pxcor < 0 and pxcor >= (no-of-gantries - no-of-gantries - no-of-gantries) and pycor = 1] [set pcolor red]
  ]
  ;bidirectional gantires
  [
    ask patches with [pxcor mod 2 = 0 and pxcor > 0 and pxcor <= no-of-gantries and pycor = 0] [set pcolor green]
    ask patches with [pxcor mod 2 = 0 and pxcor < 0 and pxcor >= (no-of-gantries - no-of-gantries - no-of-gantries) and pycor = 1] [set pcolor green]
  ]
  ask patches with [pxcor mod 2 = 0 and pxcor < 0 and pxcor >= (no-of-gantries - no-of-gantries - no-of-gantries) and pycor = 0] [set pcolor green]
  ask patches with [pxcor mod 2 = 0 and pxcor > 0 and pxcor <= no-of-gantries and pycor = 1] [set pcolor green]
  ask patches with [pxcor mod 2 = 0 and pxcor < 0 and pxcor >= (no-of-gantries - no-of-gantries - no-of-gantries) and pycor = 0] [set pcolor green]
  set gantries(patches with [pcolor = green or pcolor = red])
  
  ;To begin all patches, set their variables busy? ""
  ask patches [set busy? ""]
end

to setup-locations
  
  ;Patches where individuals can be spawned
  set individual-spawn patches with 
  [
    ;sprawn points at the sides
    ((pycor <= max-pycor and pycor > 6) or 
      (pycor >= min-pycor and pycor <= -6) and 
      (pxcor = max-pxcor or pxcor = min-pxcor)) or 
  ;sprawn points top and below
    ((pxcor <= max-pxcor and pxcor >= min-pxcor) and 
      (pycor = max-pycor or pycor <= min-pycor))
  ]
  
  ;Patches where individuals leave the model
  set individual-die (patches with [pycor > max-pycor or pycor < min-pycor or pxcor > max-pxcor or pxcor < min-pycor])
end

to-report find-nearest-empty-gantry
  
end

to-report check-conformity
  ;check conformity level of each agent
end

to-report check-someone-is-at-gantry
  ;check if there's anyone at the gantry 
end

to-report check-someone-is-at-the-other-side
  ;check if there's another person at the other side
end 

to error2-occurs
  
end

to error3-occurs
  
end

to enter-gantry
  set pass-gantry? true
  ifelse (color = blue)
  [
    vacate
    set ycor ycor - 1
    occupy
  ]
  [
    vacate
    set ycor ycor + 1
    occupy
  ]
end

to tap
  ;set a probability of the occurrence of these 2 errors and that of entering the gantry
  run one-of (list 
    task error2-occurs
    task error3-occurs
    task enter-gantry
    )
end

to spawn-individual
  if (ticks = tick-to-arrival) [
    ;no. of individuals to spawn (0 to 4)
    let no-of-sprouts random 5
    
    let no-of-sprouts-top random 5
    let no-of-sprouts-bottom random 5
    
    ;count existing indivduals at the top
    let count-individuals count individuals with [color = blue]
    
    if (no-of-sprouts-top + count-individuals) > top-max-individuals
    [set no-of-sprouts-top top-max-individuals - count-individuals ]
    
    ;start spawning individuals at the top
    repeat no-of-sprouts-top
    [
      let spawn-patch find-top-free-individual-spot
      if spawn-patch != nobody
      [
        ask spawn-patch
        [ 
          sprout-individuals 1
          [
            setup-individual
            occupy
          ]
        ]
      ]
    ]
    
    
    ;count existing indivduals at the bottom
    set count-individuals count individuals with [color = violet]
    
    if (no-of-sprouts-bottom + count-individuals) > bottom-max-individuals
    [set no-of-sprouts-bottom bottom-max-individuals - count-individuals ]
    
    ;start spawning individuals at the bottom
    repeat no-of-sprouts-bottom
    [
      let spawn-patch find-bottom-free-individual-spot
      if spawn-patch != nobody
      [
        ask spawn-patch
        [ 
          sprout-individuals 1
          [
            setup-individual
            occupy
          ]
        ]
      ]
    ]
  ]
  set tick-to-arrival (ticks + 1 + round random-exponential arrival-rate)
end

to-report find-free-individual-spot
  report one-of individual-spawn with [busy? = ""]
end

to-report find-top-free-individual-spot
  report one-of individual-spawn with [busy? = "" and pycor > 0 and (pxcor < -1 or pxcor > 1) ]
end

to-report find-bottom-free-individual-spot
  report one-of individual-spawn with [busy? = "" and pycor < 0 and (pxcor < -1 or pxcor > 1) ]
end

;To make individuals move
to move
  ask individuals[
    let patch-color pcolor
    
    ;;Check the current path grey whether the agent is able to cross or crossing the gantry
    if(patch-color = grey) [
      ifelse pass-gantry?
      [
        ;;move to the other end
      ]
      [
        ;;performs the tap action
        
      ]
    ]
    
    
    ;; Check the current patch color
    if (patch-color = yellow) [
      if (color = violet) [
        ifelse direction = "unidirection"
        [
          ifelse (xcor > -2) 
          [ 
            vacate 
            set xcor xcor - 1 
            occupy 
          ]
          [ 
            ifelse [pcolor] of patch pxcor (pycor + 1) != white 
            [ 
              vacate
              set ycor ycor + 1 
              occupy
              show "R"
            ]
            [
              show "E"
              occupy
              let counter-limit 0
              ;set counter-limit (- ycor)
              set counter-limit (- ycor - 1)
              set patch-color ([pcolor] of patch pxcor 0)
              determine-movement counter-limit patch-color
            ] 
          ] 
        ]
        [
          ;check for whether the signs are up
          ifelse signs 
          [
            ;;if the signs are up, check for conformity level
            ifelse conformity <= society-conformity-level
            [
              ifelse (xcor > -2) 
              [ 
                vacate 
                set xcor xcor - 1 
                occupy 
              ]
              [ 
                ifelse [pcolor] of patch pxcor (pycor + 1) != white 
                [ 
                  vacate
                  set ycor ycor + 1 
                  occupy
                ]
                [
                  occupy
                  let counter-limit 0
                  set counter-limit (- ycor)
                  set patch-color ([pcolor] of patch pxcor 0)
                  determine-movement counter-limit patch-color
                ] 
              ] 
            ]
            [
              ifelse [pcolor] of patch pxcor (pycor + 1) != white 
              [ 
                vacate
                set ycor ycor + 1 
                occupy
              ]
              [
                occupy
                let counter-limit 0
                set counter-limit (- ycor)
                set patch-color ([pcolor] of patch pxcor 0)
                determine-movement counter-limit patch-color
              ] 
            ]
          ]
          [
            ifelse [pcolor] of patch pxcor (pycor + 1) != white 
            [ 
              vacate 
              set ycor ycor + 1 
              occupy 
            ]
            [
              occupy
              let counter-limit 0
              set counter-limit (- ycor)
              set patch-color ([pcolor] of patch pxcor 0)
              determine-movement counter-limit patch-color
            ]  
          ]
        ]
      ]
      
      if (color = blue) [
        ifelse direction = "unidirection"
        [
          ifelse (xcor < 2)
          [ 
            vacate 
            set xcor xcor + 1 
            occupy 
          ]
          [
            ifelse [pcolor] of patch pxcor (pycor - 1) != white 
            [ 
              vacate 
              set ycor ycor - 1 
              occupy 
            ]
            [
              occupy
              let counter-limit 0
              set counter-limit (ycor - 1)
              ;              show counter-limit
              set patch-color ([pcolor] of patch pxcor 1)
              show patch-color
              determine-movement counter-limit patch-color
            ]
          ] 
        ]
        [
          ifelse signs
          [
            ifelse conformity <= society-conformity-level
            [
              ifelse (xcor < 2)
              [ 
                vacate 
                set xcor xcor + 1 
                occupy 
              ]
              [
                ifelse [pcolor] of patch pxcor (pycor - 1) != white 
                [ 
                  vacate 
                  set ycor ycor - 1 
                  occupy 
                ]
                [
                  occupy
                  let counter-limit 0
                  set counter-limit (ycor - 1)
                  ;show counter-limit
                  set patch-color ([pcolor] of patch pxcor 1)
                  show patch-color
                  determine-movement counter-limit patch-color
                ]
              ] 
            ]
            [
              ifelse [pcolor] of patch pxcor (pycor - 1) != white 
              [ 
                vacate 
                set ycor ycor - 1 
                occupy 
              ]
              [
                occupy
                let counter-limit 0
                set counter-limit (ycor - 1)
                ;              show counter-limit
                set patch-color ([pcolor] of patch pxcor 1)
                show patch-color
                determine-movement counter-limit patch-color
              ]
            ]
          ]
          [
            ifelse [pcolor] of patch pxcor (pycor - 1) != white 
            [ 
              vacate 
              set ycor ycor - 1 
              occupy 
            ]
            [
              occupy
              let counter-limit 0
              set counter-limit (ycor - 1)
              ;              show counter-limit
              set patch-color ([pcolor] of patch pxcor 1)
              show patch-color
              determine-movement counter-limit patch-color
            ]
          ]
        ]  
      ]
    ]
    
    if(patch-color = white) [
      
      let counter-limit 0
      ;let my-counter 1
      ;while [[busy?] of patch pxcor (pycor + my-counter) != "" and pycor < 0]
      ;[
      ; set counter-limit counter-limit + 1
      ; set my-counter my-counter + 1
      ;]
      
      
      
      ifelse (color = blue) 
      [ 
        ;set counter-limit (ycor - 1)
        set patch-color ([pcolor] of patch pxcor 1)
        ifelse ([busy?] of patch pxcor 1 != "")
        [
          let my-counter 1
          
          while [my-counter < 4 and [busy?] of patch pxcor my-counter != ""]
          [
            if ([busy?] of patch pxcor my-counter != "")
            [
              set my-counter my-counter + 1
              set counter-limit counter-limit + 1
            ]
          ]
        ]
        [
          set counter-limit ycor - 1
        ]
        set patch-color ([pcolor] of patch pxcor 1)
      ]
      [ 
        ;set counter-limit (- ycor)
        ifelse ([busy?] of patch pxcor 0 != "")
        [
          let my-counter 0
          
          while [my-counter < 4 and [busy?] of patch pxcor (- my-counter) != ""]
          [
            if ([busy?] of patch pxcor (- my-counter) != "")
            [
              set my-counter my-counter + 1
              set counter-limit counter-limit + 1
            ]
          ]
          show (word " limit " counter-limit)
        ]
        [
          set counter-limit (- ycor)
        ]
        
        set patch-color ([pcolor] of patch pxcor 0)
      ]
      determine-movement counter-limit patch-color
    ]
  ]
end

to determine-movement [counter-limit gantry-patch-color]
  let selected-patch nobody
  if(gantry-patch-color = green or gantry-patch-color = red) [ 
    
    ;determine the search "radius"
    ;search left and search right
    let right-count 0
    let left-count 0
    
    ifelse (color = violet)
    [
      ;for right side
      set selected-patch patch (pxcor + 1) 0
      
      ifelse((pxcor + 1 < max-pxcor) and [pcolor] of selected-patch != black) [ 
        let counter 1
        ;while [ counter < counter-limit ]
        while [ counter < counter-limit and [busy?] of patch (pxcor + 1) (pycor + counter) = ""]
        [ 
          if [busy?] of patch (pxcor + 1) (pycor + counter) = "" [ 
            set right-count (right-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      [
        set right-count -1
      ]
      
      ;for left side
      set selected-patch patch (pxcor - 1) 0
      ifelse((pxcor - 1 > min-pxcor) and [pcolor] of selected-patch != black) [
        let counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor - 1) (pycor + counter) = "" ]
        [
          if [busy?] of patch (pxcor - 1) (pycor + counter) = "" [ 
            set left-count (left-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      [
        set left-count -1
      ]
      
      ;show  (word " right " right-count " left " left-count)
      
      ;compare right and left count
      if (right-count > left-count ) [
        vacate 
        set ycor (ycor + 1) 
        vacate
        set xcor (xcor + 1) 
        occupy
      ]
      if (left-count > right-count) [ 
        vacate 
        set ycor (ycor + 1) 
        vacate
        set xcor (xcor - 1) 
        occupy
      ]
      if (left-count = right-count) [ 
        ifelse random-float 1 < 0.5
        [ 
          vacate 
          set ycor (ycor + 1) 
          vacate
          set xcor (xcor + 1) 
          occupy 
        ] 
        [ 
          vacate 
          set ycor (ycor + 1) 
          vacate
          set xcor (xcor - 1) 
          occupy 
        ] 
      ]
      ;occupy
    ]
    [ 
      ;for right side
      set selected-patch patch (pxcor - 1) 1
      
      ifelse((pxcor - 1 > min-pxcor) and [pcolor] of selected-patch != black) [
        let counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor - 1) (pycor - counter) = "" ]
        [
          if [busy?] of patch (pxcor - 1) (pycor - counter) = "" [ 
            set right-count (right-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      [
        set right-count -1
      ]
      
      ;for left side
      set selected-patch patch (pxcor + 1) 1
      ifelse((pxcor + 1 < max-pxcor) and [pcolor] of selected-patch != black) [
        let counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor + 1) (pycor - counter) = "" ]
        [
          if [busy?] of patch (pxcor + 1) (pycor - counter) = "" [ 
            set left-count (left-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      [
        set left-count -1
      ]
      
      
      if (right-count > left-count ) [
        vacate 
        set ycor (ycor - 1) 
        vacate
        set xcor (xcor - 1) 
        occupy
      ]
      if (left-count > right-count) [ 
        vacate 
        set ycor (ycor - 1) 
        vacate
        set xcor (xcor + 1) 
        occupy
      ]
      if (left-count = right-count) [ 
        ifelse random-float 1 < 0.5
        [ 
          vacate 
          set ycor (ycor - 1) 
          vacate
          set xcor (xcor + 1) 
          occupy 
        ] 
        [ 
          vacate 
          set ycor (ycor - 1) 
          vacate
          set xcor (xcor + 1) 
          occupy 
        ] 
      ]
    ]        
  ]
  
  
  
  if(gantry-patch-color = grey)
  [
    ;search the current lane, right and left
    let centre-count 0; 
    let right-count 0;
    let left-count 0;
    
    ifelse (color = violet)
    [ 
      let counter 1
      while [ counter < counter-limit and [busy?] of patch pxcor (pycor + counter) = ""]
      [
        if [busy?] of patch pxcor (pycor + counter) = "" [ 
          set centre-count (centre-count + 1) 
          set counter (counter + 1) 
        ]
      ]
      
      set selected-patch patch (pxcor + 2) 0
      if((pxcor + 2 < max-pxcor) and [pcolor] of selected-patch != black) [ 
        set counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor + 2) (pycor + counter) = ""]
        [ 
          if [busy?] of patch (pxcor + 2) (pycor + counter) = "" [ 
            set right-count (right-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      
      
      
      set selected-patch patch (pxcor - 2) 0
      if((pxcor - 2 > min-pxcor) and [pcolor] of selected-patch != black) [
        set counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor - 2) (pycor + counter) = ""]
        [
          if [busy?] of patch (pxcor - 2) (pycor + counter) = "" [ 
            set left-count (left-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      
      
      
      
      ;; If the patch color in front is grey, stop and tap.
      if ([pcolor] of patch pxcor (pycor + 1) != grey)
      [
        ifelse((centre-count >= right-count or centre-count >= left-count) and ([busy?] of patch pxcor (pycor + 1) = "" )) [ 
          ;show "A"
          ;; Enter the current-facing gantry
          vacate 
          set ycor (ycor + 1) 
          occupy 
        ][
        ;show  (word " right " right-count " left " left-count)
        ;; Decide which gantry to enter
        show word "right" right-count
        show word "left" left-count
        if ((right-count > left-count) and switched-lane? = false)
        [ 
          show "C"
          set switched-lane? true
          vacate 
          set ycor (ycor + 1) 
          ;vacate
          set xcor (xcor + 2) 
          occupy 
        ]
        if ((right-count < left-count) and switched-lane? = false)
        [ 
          show "D"
          set switched-lane? true
          vacate
          set ycor (ycor + 1)
          ;vacate
          set xcor (xcor - 2) 
          occupy 
        ] 
        ]
      ]
    ]
    [ 
      let counter 1
      while [ counter < counter-limit and [busy?] of patch pxcor (pycor - counter) = ""]
      [
        if [busy?] of patch pxcor (pycor - counter) = "" [ 
          set centre-count (centre-count + 1) 
          set counter (counter + 1) 
        ]
      ]
      
      set selected-patch patch (pxcor -  2) 1
      if((pxcor - 2 > min-pxcor) and [pcolor] of selected-patch != black) [
        set counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor - 2) (pycor - counter) = ""]
        [
          if [busy?] of patch (pxcor - 2) (pycor - counter) = "" [ 
            set right-count (right-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]        
      
      set selected-patch patch (pxcor + 2) 1
      if((pxcor + 2 < max-pxcor) and [pcolor] of selected-patch != black) [
        set counter 1
        while [ counter < counter-limit and [busy?] of patch (pxcor + 2) (pycor - counter) = ""]
        [
          if [busy?] of patch (pxcor + 2) (pycor - counter) = "" [ 
            set left-count (left-count + 1) 
            set counter (counter + 1) 
          ]
        ]
      ]
      
      ;show  (word " right " right-count " left " left-count  " center " centre-count)
      
      ;; If the patch color in front is grey, stop and tap.
      if ([pcolor] of patch pxcor (pycor + 1) != grey)
      [
        
        ifelse ((centre-count >= right-count or centre-count >= left-count) and ([busy?] of patch pxcor (pycor - 1) = "")) [ 
          ;show "A"
          ;; Enter the current-facing gantry
          vacate 
          set ycor (ycor - 1) 
          occupy 
        ][
        
        ;show  (word " right " right-count " left " left-count)
        ;; Decide which gantry to enter
        if ((right-count > left-count) and switched-lane? = false)
        [ 
          show "C"
          set switched-lane? true
          vacate 
          set ycor (ycor - 1) 
          ;vacate
          set xcor (xcor - 2) 
          occupy 
        ]
        if ((right-count < left-count) and switched-lane? = false)
        [ 
          show "D"
          set switched-lane? true
          vacate
          set ycor (ycor - 1)
          ;vacate
          set xcor (xcor + 2) 
          occupy 
        ] 
        ]
      ]
    ]
  ]
end

;The following functions are used to change the busy? variable of a patch appropriately when an agent is arriving or leaving it
to occupy
  ask patch-here [set busy? "Yes"]
end

to vacate
  ask patch-here [set busy? ""]
end
@#$#@#$#@
GRAPHICS-WINDOW
507
10
1088
474
14
-1
19.7
1
10
1
1
1
0
1
1
1
-14
14
-10
11
0
0
1
ticks
30.0

BUTTON
6
10
72
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
10
148
43
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
159
10
222
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
248
10
473
43
no-of-gantries
no-of-gantries
8
20
14
2
1
NIL
HORIZONTAL

SLIDER
5
168
210
201
top-max-individuals
top-max-individuals
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
5
214
210
247
bottom-max-individuals
bottom-max-individuals
0
100
93
1
1
NIL
HORIZONTAL

CHOOSER
248
56
386
101
direction
direction
"unidirection" "bidirection"
0

SWITCH
248
114
351
147
Signs
Signs
0
1
-1000

SLIDER
248
169
440
202
society-conformity-level
society-conformity-level
0
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
5
261
210
294
arrival-rate
arrival-rate
1
10
5
1
1
NIL
HORIZONTAL

SLIDER
248
216
440
249
society-patience-level
society-patience-level
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
248
262
440
295
society-prepareness-level
society-prepareness-level
0
1
0.1
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
