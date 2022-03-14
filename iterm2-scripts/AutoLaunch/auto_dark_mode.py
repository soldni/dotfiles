#!/usr/bin/env python3

import asyncio
import iterm2
from dataclasses import dataclass
from typing import Type, TypeVar


FS = TypeVar('FS', bound='FontSpec')

@dataclass
class FontSpec:
    name: str
    size: int
    weight: str = None

    @classmethod
    def from_string(cls: Type[FS], string: str) -> FS:
        name_weight, size, *_ = string.split(' ')
        name, *weight = name_weight.split('-')
        weight = weight or None
        return FontSpec(name=name, weight=weight[0], size=int(size))

    def to_string(self: FS) -> str:
        weight = f'-{self.weight}' if self.weight else ''
        return f'{self.name}{weight} {self.size}'


async def main(connection):
    monitor_args = (connection, iterm2.VariableScopes.APP, "effectiveTheme", None)
    async with iterm2.VariableMonitor(*monitor_args) as mon:
        while True:
            # Block until theme changes
            theme = await mon.async_get()

            # Themes have space-delimited attributes, one of which will be light or dark.
            parts = theme.split(" ")
            if "dark" in parts:
                preset = await iterm2.ColorPreset.async_get(connection, "Dracula")
                font = FontSpec('FiraCodeRoman', 15, 'Regular')
            else:
                preset = await iterm2.ColorPreset.async_get(connection, "one-light-terminal")
                font = FontSpec('FiraCodeRoman', 15, 'Medium')

            # Update the list of all profiles and iterate over them.
            profiles = await iterm2.PartialProfile.async_query(connection)
            for partial in profiles:
                # Fetch the full profile and then set the color preset in it.
                profile = await partial.async_get_full_profile()

                new_font = font.to_string()
                print(new_font)
                await profile.async_set_normal_font(new_font)
                # await change.async_set_color_preset(preset)
                await profile.async_set_color_preset(preset)

iterm2.run_forever(main)
