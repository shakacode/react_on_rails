1. Referencing CSS/Sass module files requires specifying the full extension of
   '.module.scss'. Otherwise, the file loads, but no CSS modules are applied.
2. extract_css should be false for development if one wants to use HMR for styles,
   which is typically more efficient.
