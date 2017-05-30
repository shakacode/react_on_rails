import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import MainPageRedux from './MainPageRedux';

import * as mainPageActions from '../actions/MainPageActions';

const MainPageContainer = ({ actions, data, railsContext }) => (
  <MainPageRedux {...{ actions, data, railsContext }} />
);
MainPageContainer.propTypes = {
  actions: PropTypes.object.isRequired,
  data: PropTypes.object.isRequired,
  railsContext: PropTypes.object.isRequired,
};

function mapStateToProps(state) {
  return {
    data: state.mainPageData,
    railsContext: state.railsContext,
  };
}

function mapDispatchToProps(dispatch) {
  return { actions: bindActionCreators(mainPageActions, dispatch) };
}

// Don't forget to actually use connect!
export default connect(mapStateToProps, mapDispatchToProps)(MainPageContainer);
