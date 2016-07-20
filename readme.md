CircuitLogger
=========== 

Version: 1.0.0

Adds an entity that allows log circuit network signals in wires connected to that entity.

Features:
- logs every signal change (tick by tick) from all wires connected to it into a csv file
- it is possible to specify signals that will not be logged (globally for all loggers, as well as individually for each logger)
- option for logging only specified wire types
- assigning aliases to signals
- loggers can be named
- parsing "binary" signals and logging specified bits to separate columns
- it is possible to set up trigges that will turn logging on/off either manually, or automatically after certain time or based on circuit/logistic network conditions
                                                                                            
How to use it:
1. Build the circuit logger(s) and connect it to the network
2. Click on the logger and specify what to log
3. Set trigger options or just start logging manually
4. When logging stops, a csv file called  "start_tick-end_tick.csv" with logged signals will be saved to the folder "script-output/circuit_logger"

Description of the Circuit Logger Settings window:
- Name: name of the logger that will be visible in the og file
- Start trigger: starts logging as soon as a condition is met
- Stop trigger: turns off logging when a condition is met (but will not do so as long as the "logging on" condition is met)
- Logging is on: as long as the condition is met, logging continues regardless of any events defined in the "stop trigger". Logging stops when the condition is not met any more.
- Log red wire: logs signals from the red wire connected to the logger 
- Log green wire: logs signals from the green wire connected to the logger
- Log both combined: logs signals from both wires connected to the logger and combines them (addition of the red and green wire signals)
- Ignored signals: Comma separated signal names (Factorio internal signal names, not localized names shown in the game!) in this field will not be logged by the particular logger. No spaces allowed, case sensitive. (Example: "signal-red,signal-A,diesel-locomotive")
- Signal aliases: enable setting custom names for specified signals + configuration for binary type signals
- Update: click to update the logger settings

Description of the Global Circuit Logger Settings window:
- Status: Status of logging; the logger that triggered the last status change is displayed in parentheses
- Logged records: Number of records in the current log
- Stop trigger after... (ticks): If checked, it will stop logging after a specified number of ticks from the last "start trigger" event. Each "start trigger" event during logging will reset counter of remaining ticks.
- Ignored signals: Names of signals ignored by all loggers. Same syntax as in case of the circuit logger.
- Update: click to update the logger settings
- Start trigger: press to start logging (regardless of any triggers defined)
- Stop trigger: press to stop logging (will not work if a "logging on" condition is met for any logger)

Syntax of signal aliases:
signal_name=alias - all separated by commas. No spaces around signal name. Symbols "=,{}" are not allowed in aliases. (Example: "signal-red=Line busy,signal-A=Counter")

Binary signals:
Binary signals are defined by the alias of the signal that should be interpreted as a binary signal. 

Format: signal_name={bit:name_of_displayed_column;bit:name_of_the_displayed_column;....}
- Bit: index of bit, counted from 1 (lowest bit) to 32 (highest bit)
- Name of the displayed column: Name that will be shown in the column header; symbols: "{},;=:" are not allowed

Example: "signal-A={1:Require items;2:Items sent};signal-B={3:Minutes tick;1:Seconds tick}"

Bit settings are separated by semicolons.

The order of bits is not important. It is not necessary to specify all 32 bits.    

Change log:
1.0.0: CircuitLogger was created


Ideas for future development:
- "pretrigger" - logs also signals from a specified time frame before the current logging was triggered (either manually or because a condition had been met)
- in case of longer logs, write data to the file in chunks so that lags in the game are avoided when logging is finished
- possibility of using localized signal names in the log files