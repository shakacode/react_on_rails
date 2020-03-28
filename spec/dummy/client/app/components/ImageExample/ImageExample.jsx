import React from 'react';

// Note the global alias for image
// eslint-disable-next-line import/no-unresolved
import logo from 'Assets/images/256egghead.png';
// eslint-disable-next-line import/no-unresolved
import legoIcon from 'Assets/images/lego_icon.svg';

import css from './ImageExample.scss';
import bowerLogo from './bower.png';
import blueprintIcon from './blueprint_icon.svg';

const TestComponent = (_props) => (
  <div>
    <h1 className={css.red}>This is a test of CSS module color red.</h1>
    <hr />
    <h1 className={css.background}>Here is a label with a background-image from the CSS modules imported</h1>
    <img src={logo} alt="logo" />
    <hr />
    <h1 className={css.backgroundSameDirectory}>
      This label has a background image from the same directory. Below is an img tag in the same directory
    </h1>
    <img src={bowerLogo} alt="bower logo" />
    <hr />
    <h1> Below is an img tag of a svg in the same directory</h1>
    <img src={blueprintIcon} alt="blueprint icon" />
    <hr />
    <h1>Below is a div with a background svg</h1>
    <div className={css.googleLogo} alt="google logo" />
    <hr />
    <h1>SVG lego icon img tag with global path</h1>
    <img src={legoIcon} alt="lego icon" />
    <hr />
    <h1>SVG lego icon with background image to global path</h1>
    <div className={css.legoIcon} alt="lego icon again" />
  </div>
);

export default TestComponent;
