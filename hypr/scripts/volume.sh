#!/bin/bash

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')

notify-send -h int:value:$volume \
            -h string:x-canonical-private-synchronous:volume \
            "Volume: ${volume}%"
