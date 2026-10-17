#!/bin/zsh
# Shows what the widget daemon (chronod) did with the World Clock extension in the last few minutes.
# Healthy: lines about fetching descriptors / "kind: com.ac1982.worldclock.cities". Unhealthy: "purging" / "restricted".
pluginkit -m -v -i com.ac1982.worldclock.widget
/usr/bin/log show --last "${1:-5m}" --style compact --predicate 'process == "chronod"' 2>/dev/null \
  | grep -E "ac1982" | cut -c1-24,60-260 | tail -25
