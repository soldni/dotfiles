from sys import platform, stderr

try:
    import darkdetect
except ImportError:
    darkdetect = None


# Default options that apply in any case
c.InteractiveShell.color_info = True
c.TerminalInteractiveShell.highlight_matching_brackets = True
c.TerminalInteractiveShell.true_color = True

# Additional options to override if on macos and have darkdetect installed
c.InteractiveShell.colors = 'Neutral'
c.TerminalInteractiveShell.colors = 'Neutral'
c.TerminalInteractiveShell.highlighting_style = 'legacy'

if platform == "darwin":
    if darkdetect is not None:
        if darkdetect.isLight():
            c.InteractiveShell.colors = 'LightBG'
            c.TerminalInteractiveShell.colors = 'Linux'
            c.TerminalInteractiveShell.highlighting_style = 'xcode'
        elif darkdetect.isDark():
            c.InteractiveShell.colors = 'Linux'
            c.TerminalInteractiveShell.colors = 'Linux'
            c.TerminalInteractiveShell.highlighting_style = 'dracula'
    else:
        print('[iPython] Package "darkdetect" not installed!',
              file=stderr)