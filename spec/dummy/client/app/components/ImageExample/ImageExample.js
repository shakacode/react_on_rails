import React from 'react';
import PropTypes from 'prop-types';
import css from './ImageExample.scss';

// Note the global alias for images
import logo from 'images/256egghead.png';
import bowerLogo from './bower.png';
import blueprintIcon from './blueprint_icon.svg';
import legoIcon from 'images/lego_icon.svg';
const TestComponent = (props) => (
  <div>
    <h1 className={css.red}>This is a test of CSS module color red.</h1>
    <hr/>
    <h1 className={css.background}>Here is a label with a background-image from the CSS modules
      imported</h1>
    <img src={logo}/>
    <hr/>
    <h1 className={css.backgroundSameDirectory}>This label has a background image from the same
      directory. Below is an img tag in the same directory</h1>
    <img src={bowerLogo}/>
    <hr/>
    <h1> Below is an img tag of a svg in the same directory</h1>
    <img src={blueprintIcon}/>
    <hr/>
    <h1>Below is a div with a background svg</h1>
    <div className={css.googleLogo}/>
    <hr/>
    <h1>SVG lego icon img tag with global path</h1>
    <img src={legoIcon}/>
    <hr/>
    <h1>SVG lego icon with background image to global path</h1>
    <div className={css.legoIcon}/>
  </div>
);

TestComponent.propTypes = {
  message: PropTypes.string,
};

export default TestComponent;
