globals [
  customers-created    ; Flag to check if customers have been created
  customer-count       ; Number of customers created
  counters-created?    ; Flag to track if counters are initialized
  service-time         ; Time to serve a customer at the counter
  red-departures       ; Customers leaving through red counters
  cyan-departures      ; Customers leaving through cyan counter
  income               ; Total income from purchases
  missed-income        ; Potential income from customers who left without purchasing
]

; Turtle properties
turtles-own [
  last-heading         ; Track previous direction
  blue-hits            ; Product counter (price)
  heading-to-counter?  ; Check if going to counter
  assigned-counter     ; Which counter assigned to
  waiting-time         ; Time spent waiting in queue
  going-to-cyan?       ; Flag for leaving via cyan counter
]

; Counter properties (queues)
patches-own [
  queue                ; List of turtles in queue
  serving-timer        ; Timer for current customer
]

to setup
  clear-all
  set counters-created? false   ; Reset counter flag
  setup-store-layout
  reset-ticks
  set customers-created false   ; Reset creation flag
  set customer-count 0          ; Reset customer count
  set service-time 5            ; Default service time (can be slider)
  set red-departures 0          ; Initialize red counter departures
  set cyan-departures 0         ; Initialize cyan counter departures
  set income 0                  ; Initialize income
  set missed-income 0           ; Initialize missed income
end

to setup-store-layout
  ; Default background (black)
  ask patches [set pcolor black]

  ; Entrance zone (yellow)
  ask patches with [pxcor > 0 and pycor < 0] [set pcolor yellow]

  ; Checkout zone (grey)
  ask patches with [pxcor <= 0 and pycor < 0] [set pcolor grey]

  ; Leave with no product zone (cyan)
  ask patch 0 -6 [set pcolor cyan]

  ; Create product places (blue)
  ask patches with [pycor > 0 and member? (pxcor mod 6) [2 1] and not member? (pycor mod 12) [0 1]] [
    set pcolor blue
  ]

  ; Create counters based on slider
  setup-counters
end

to setup-counters
  ; Only create counters once per setup
  if counters-created? [ stop ]

  ; Clear old counters
  ask patches with [pcolor = red] [
    set pcolor grey
    set queue []
    set serving-timer 0
  ]

  ; Place new counters at bottom of grey area
  let y-pos min-pycor   ; Bottom row (y = -6 in default world)
  let min-x min-pxcor   ; Left edge
  let max-x -1          ; Right edge (avoid cyan patch at 0)

  ; Calculate spacing between counters
  let available-space (max-x - min-x)
  let spacing floor (available-space / (number-of-counters + 1))

  ; Create counters using local counter variable
  let counter 0
  repeat number-of-counters [
    ; Calculate position based on counter index
    let x-pos min-x + (spacing * (counter + 1))
    ask patch x-pos y-pos [
      set pcolor red
      set queue []              ; Initialize empty queue
      set serving-timer 0       ; Reset serving timer
    ]
    set counter counter + 1  ; Increment local counter
  ]
  set counters-created? true
end

to go
  ; Stop simulation only when all customers have been created and none remain
  if customers-created and not any? turtles [
    stop
  ]

  if customers-created = false [
    create-customers
    set customer-count customer-count + 1
    if customer-count >= NUMBER-OF-CUSTOMERS [
      set customers-created true
    ]
  ]

  ask turtles [
    ; Check if leaving without products
    if pcolor = cyan [
      set cyan-departures cyan-departures + 1  ; Count cyan departure
      set missed-income missed-income + blue-hits ; Add to missed income
      die
    ]

    ; Handle counter logic
    if (pcolor = grey) and (not heading-to-counter?) and (blue-hits > 0) and (not going-to-cyan?) [
      assign-to-counter
    ]

    ; Handle customers without products in grey area
    if (blue-hits = 0) and (pcolor = grey) and (not going-to-cyan?) [
      face patch 0 -6  ; Face the exit
      fd 1
    ]

    ; State machine for customer behavior
    ifelse going-to-cyan? [
      move-to-cyan
    ]
    [
      ifelse heading-to-counter? [
        move-to-counter
      ]
      [
        wander
      ]
    ]
  ]

  ; Process counters and queues
  process-counters

  ; Update plot
  update-plot

  tick
end

to create-customers
  create-turtles 1 [
    set shape "person"
    set color lime
    set size 1
    set blue-hits 0
    ; Appear from yellow patches near bottom-right
    let entry-patch one-of patches with [
      pcolor = yellow and
      pxcor >= (max-pxcor - 3) and
      pycor <= (min-pycor + 2)
    ]
    if entry-patch != nobody [
      move-to entry-patch
    ]
    set last-heading heading
    set heading-to-counter? false
    set going-to-cyan? false
    set assigned-counter nobody
    set label ""  ; Initialize label
    set waiting-time 0
  ]
end

to assign-to-counter
  set heading-to-counter? true
  set going-to-cyan? false

  ; Find counter with shortest queue
  let counters patches with [pcolor = red]

  ; Calculate queue lengths using a separate reporter
  set assigned-counter min-one-of counters [
    count-queue-length self
  ]

  ; Add customer to the counter's queue
  ask assigned-counter [
    set queue lput myself queue
  ]

  ; Check if customer should leave for cyan counter
  let q [queue] of assigned-counter
  let my-position position self q
  ; Number of customers ahead in queue
  let customers-ahead ifelse-value (my-position = false) [0] [my-position]

  if customers-ahead > blue-hits [
    ; Remove customer from queue
    ask assigned-counter [
      set queue remove-item my-position queue
    ]
    set going-to-cyan? true
    set heading-to-counter? false
    set assigned-counter nobody
  ]
end

; Helper reporter to calculate queue length for a counter
to-report count-queue-length [cnt]
  ; In patch context (cnt is a patch)
  let q-length length [queue] of cnt
  let approaching count turtles with [
    heading-to-counter? and assigned-counter = cnt
  ]
  report q-length + approaching
end

to move-to-counter
  ; Get queue position
  let q [queue] of assigned-counter
  let idx position self q

  ; If customer is not in queue (shouldn't happen), wander
  if idx = false [
    wander
    stop
  ]

  ; Calculate target position in queue
  let target-x [pxcor] of assigned-counter
  let target-y [pycor] of assigned-counter + idx + 1  ; Position above counter

  ; Move toward queue position
  if distancexy target-x target-y > 0.5 [
    facexy target-x target-y
    fd 1
  ]

  ; Update waiting time
  if distancexy target-x target-y <= 1 [
    set waiting-time waiting-time + 1
  ]
end

to move-to-cyan
  ; Move directly to cyan counter
  let target patch 0 -6
  if distance target > 0.5 [
    face target
    fd 1
  ]
end

to process-counters
  ask patches with [pcolor = red] [
    ; Process serving timer
    ifelse serving-timer > 0 [
      set serving-timer serving-timer - 1
    ]
    [
      ; Serve next customer if available
      if length queue > 0 [
        let next-customer first queue
        ask next-customer [
          set red-departures red-departures + 1  ; Count red departure
          set income income + blue-hits          ; Add to income
          die  ; Customer leaves after being served
        ]
        set queue but-first queue  ; Remove served customer
        set serving-timer service-time  ; Reset timer
      ]
    ]

    ; Update positions of remaining customers in queue
    let idx 0
    let q queue  ; Store queue in local variable
    while [idx < length q] [
      let current-customer item idx q
      ask current-customer [
        let new-x [pxcor] of myself  ; myself refers to the counter patch
        let new-y [pycor] of myself + idx + 1
        if distancexy new-x new-y > 0.5 [
          setxy new-x new-y
        ]
      ]
      set idx idx + 1
    ]
  ]
end

to wander
  let next-patch patch-ahead 1

  ; Ensure next-patch exists
  if next-patch = nobody [
    ; If at the edge, turn randomly and move
    rt random 360
    fd 1
    stop
  ]

  ifelse [pcolor] of next-patch = blue [
    ; Turn toward black area
    let black-patch one-of patches with [pcolor = black]
    if black-patch != nobody [
      face black-patch
      fd 1
      set blue-hits blue-hits + 1
      set label (word blue-hits)  ; Update price display
    ]
  ]
  [
    ; Continue forward
    fd 1
  ]

  ; Handle world edges
  if (pxcor = max-pxcor or pxcor = min-pxcor or pycor = max-pycor or pycor = min-pycor) [
    rt random 360
    fd 1
  ]

  set last-heading heading  ; Update direction memory
end

to update-plot
  set-current-plot "Income Over Time"
  set-current-plot-pen "Total Potential Income"
  plot income + missed-income
  set-current-plot-pen "Actual Income"
  plot income
end
@#$#@#$#@
GRAPHICS-WINDOW
290
20
858
607
-1
-1
18.67
1
10
1
1
1
0
1
1
1
-24
5
-6
24
1
1
1
ticks
30.0

BUTTON
3
40
130
86
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

SLIDER
3
128
274
161
Number-of-customers
Number-of-customers
0
1000
600.0
100
1
NIL
HORIZONTAL

BUTTON
139
38
272
86
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
3
206
274
239
number-of-counters
number-of-counters
1
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
871
488
1176
533
Customers Who Purchased
red-departures
17
1
11

MONITOR
1189
487
1498
532
Customers Who Left Without Purchasing
cyan-departures
17
1
11

MONITOR
871
548
1178
593
Total Income from Purchases (Rs '000)
income
17
1
11

MONITOR
1190
547
1498
592
Potential Missed Income (Rs '000)
missed-income
17
1
11

PLOT
871
21
1499
474
Income Over Time
Time (ticks)
Income
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total Potential Income" 1.0 0 -13840069 true "" "plot income + missed-income"
"Actual Income" 1.0 0 -13345367 true "" "plot income"

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
15
Circle -13840069 true false 110 5 80
Polygon -13840069 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -13840069 true false 127 79 172 94
Polygon -13840069 true false 195 90 240 150 225 180 165 105
Polygon -13840069 true false 105 90 60 150 75 180 135 105

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
