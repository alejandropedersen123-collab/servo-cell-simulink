# Visual system

The presentation follows the DESIGN.md supplied by the project owner: an indigo and navy palette, a soft multicolor SVG mesh, thin display typography, pill buttons and a cream evidence band. The implementation is original; no third-party logo, product copy or proprietary font is included.

## Tokens and source

- Primary: `#533afd`; text: `#0d253d`; dark surface: `#1c1e54`.
- Backgrounds: `#ffffff`, `#f6f9fc`, `#f5e9d4`; borders: `#e3e8ee`.
- Inter variable, display weight 300, body weight 300, controls 400.
- Display 56 px / 1.03, tracking -1.4 px; mobile 40 px / 1.08.
- Numeric results use tabular figures. Controls have visible keyboard focus and at least 44 px height on small screens.
- Layout tokens and responsive rules: `docs/assets/theme.css`.
- Original vector mesh: `docs/assets/mesh.svg`.
- Page builder and measured-result previews: `tools/presentation.py`.

`python tools/build_demo.py` produces `docs/demo.html` and `docs/index.html`. All data, styles, vector artwork and the font are embedded so the demo works offline. Documentation links lead to GitHub. Scientific MATLAB/Simulink sources and recorded numerical results are independent of the visual layer.

## Third-party font

Inter 4.1, copyright The Inter Project Authors, is redistributed unmodified under SIL Open Font License 1.1. The font and license are in `docs/assets`; the generated HTML also embeds the license. Source: https://rsms.me/inter/ and https://github.com/rsms/inter. This font is not covered by this repository's MIT license.
