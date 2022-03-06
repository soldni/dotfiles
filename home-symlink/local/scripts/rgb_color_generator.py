#! /usr/bin/env	python3

"""
Generate RGB colors that are pleasant to look at on light
and dark backgrounds

Author: Luca Soldaini
Email:  luca@soldaini.net
"""

import argparse
import copy
from enum import Enum
import hashlib
from math import pow
import os
from typing import Iterable, Sequence, Union, Generic, TypeVar
from random import random, seed
from socket import gethostname
from getpass import getuser


BRIGHTNESS_THRESHOLD = 186
CH = TypeVar('CH', bound='RgbChannel')
CL = TypeVar('CL', bound='RgbColor')
CH_VAL = Union[int, float]


class CH_NAMES(Enum):
    RED: str = 'r'
    GRN: str = 'g'
    BLE: str = 'b'


MAX_BRIGHTNESS = 186 / 255
CHANNEL_BRIGHTNESS = {CH_NAMES.RED: 0.299,
                      CH_NAMES.BLE: 0.114,
                      CH_NAMES.GRN: 0.587}


class RgbChannel(Generic[CH]):
    def __init__(self: CH, name: Union[CH_NAMES, str], value: CH_VAL):
        if isinstance(name, str):
            name = CH_NAMES(name)

        if 0. <= value <= 1. and isinstance(value, float):
            self.is_float = True
        elif 0 <= value <= 255 and isinstance(value, int):
            self.is_float = False
        else:
            raise ValueError(f'Value {value} out of bounds or not the right type')

        if name not in CH_NAMES:
            raise ValueError(f'Name {name} not in ChannelNamesEnum')

        self.value = value
        self.name = name

    def __repr__(self: CH) -> str:
        value = f'{self.value:.4f}' if self.is_float else f'{self.value:03d}'
        return f'{self.name.value}={value}'

    def __str__(self: CH) -> str:
        return str(self.value)

    def as_int(self: CH) -> CH:
        ch = copy.deepcopy(self)
        if ch.is_float:
            ch.value = round(ch.value * 255)
            ch.is_float = False
        return ch

    def as_float(self: CH) -> CH:
        ch = copy.deepcopy(self)
        if not ch.is_float:
            ch.value = ch.value / 255
            ch.is_float = False
        return ch

class RgbColor(Generic[CL]):
    def __init__(self: CL, *args: Sequence[RgbChannel]):
        [setattr(self, ch.value, None) for ch in CH_NAMES]
        for ch in args:
            setattr(self, ch.name.value, ch)
        if any(v is None for v in vars(self).values()):
            raise ValueError('Not all channels provided!')

    def __iter__(self: CL) -> Iterable[CH]:
        yield from (self.r, self.g, self.b)

    def __repr__(self: CL) -> str:
        return (f'{self.__class__.__name__} '
                f'({repr(self.r)}, {repr(self.g)}, {repr(self.b)})')

    def as_int(self: CL) -> CL:
        return self.__class__(*(ch.as_int() for ch in self))

    def as_float(self: CL) -> CL:
        return self.__class__(*(ch.as_float() for ch in self))


def generate_random_neutral_brightness(lightness: float):
    color = RgbColor(RgbChannel(name='r', value=random()),
                     RgbChannel(name='g', value=random()),
                     RgbChannel(name='b', value=random()))

    lum_per_channel = list(map(Lightness.channel_to_luminance, color))
    target_lum = Lightness.lightness_to_luminance(lightness)
    correction = target_lum / sum(lum_per_channel)

    for ch, lum in zip(color, lum_per_channel):
        ch.value = Lightness.luminance_to_channel_correction(lum * correction, ch.name)

    return color


class Lightness:
    """https://stackoverflow.com/a/56678483"""

    LUMINANCE_CORRECTION_MAP = {
        CH_NAMES.RED: 0.2126,
        CH_NAMES.GRN: 0.7152,
        CH_NAMES.BLE: 0.0722
    }
    @classmethod
    def channel_to_luminance(cls, ch: RgbChannel) -> float:
        ch = ch.as_float()
        if ch.value <= 0.04045:
            ch.value = ch.value / 12.92
        else:
            ch.value = pow((ch.value + 0.055) / 1.055, 2.4)
        return cls.LUMINANCE_CORRECTION_MAP[ch.name] * ch.value

    @classmethod
    def luminance_to_channel_correction(cls, lum: float, ch_name: CH_NAMES) -> float:
        lum = lum / cls.LUMINANCE_CORRECTION_MAP[ch_name]
        if lum <= 0.0031308:
            value = lum * 12.92
        else:
            value = pow(lum, 1 / 2.4) * 1.055 - 0.055
        return value

    @classmethod
    def lightness_to_luminance(cls, lightness: float) -> float:
        if lightness <= 0.008:
            luminance = lightness * 27 / 24.389
        else:
            luminance = pow((lightness + 0.16) / 1.16, 3)
        return luminance

    @classmethod
    def luminance_to_lightness(cls, luminance: float) -> float:
        if luminance < (216 / 24389):
            lightness = luminance * 24.389 / 27
        else:
            lightness = pow(luminance, 1 / 3) * 1.16 - 0.16
        return lightness

    def __new__(cls, rgb: RgbColor) -> float:
        luminance = sum(map(cls.channel_to_luminance, rgb))
        lightness = cls.luminance_to_lightness(luminance)
        return lightness


def parse_options():
    ap = argparse.ArgumentParser()
    ap.add_argument('-d', '--display', action='store_true')
    ap.add_argument('-s', '--seed', type=int, default=None)
    ap.add_argument('-l', '--lightness', type=float, default=0.65)
    ap.add_argument('-r', '--rgb-output', action='store_true')
    ap.add_argument('-x', '--hex-output', action='store_true')

    opts = ap.parse_args()

    if opts.seed is None:
        context = os.environ.get('LOCAL_CONTEXT_COLOR', '')
        context = f'{gethostname()}; {getuser()}; {context}'
        h = hashlib.md5(context.encode('utf-8')).hexdigest()
        opts.seed = int(h, 16)

    return opts

class color_escape:
    ESCAPE: str = '\033[{};2;{};{};{}m'
    RESET: str = '\033[0m'

    def __new__(cls, color: CL, background: bool = False) -> str:
        color = color.as_int()
        return cls.ESCAPE.format(48 if background else 38, color.r, color.g, color.b)

    @classmethod
    def foreground(cls, color: CL) -> str:
        return cls(color, background=False)

    @classmethod
    def background(cls, color: CL) -> str:
        return cls(color, background=True)

    @classmethod
    def reset(cls):
        return cls.RESET


def main():
    opts = parse_options()
    if opts.seed:
        seed(opts.seed)

    random_color = generate_random_neutral_brightness(opts.lightness).as_int()

    if opts.display:
        black = RgbColor(RgbChannel('r', 0.), RgbChannel('b', 0.), RgbChannel('g', 0.))
        white = RgbColor(RgbChannel('r', 1.), RgbChannel('b', 1.), RgbChannel('g', 1.))

        print(f'Color {repr(random_color)} (lightness={Lightness(random_color):.2f}):')
        print(color_escape.foreground(random_color) +
              'ON CURRENT BACKGROUND' +
              color_escape.reset())
        print(color_escape.foreground(random_color) +
              color_escape.background(black) +
              'ON A DARK BACKGROUND' +
              color_escape.reset())
        print(color_escape.foreground(random_color) +
              color_escape.background(white) +
              'ON A LIGHT BACKGROUND' +
              color_escape.reset())

    elif opts.rgb_output:
        print(';'.join(map(str, random_color.as_int())))

    elif opts.hex_output:
        print('#' + ''.join(hex(ch.value).lstrip("0x")
                            for ch in random_color.as_int()), end='')

if __name__ == '__main__':
    main()
