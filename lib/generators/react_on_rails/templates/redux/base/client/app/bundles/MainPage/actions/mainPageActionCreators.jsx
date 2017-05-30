/* eslint-disable import/prefer-default-export */

import { MAIN_PAGE_NAME_UPDATE } from '../constants/mainPageConstants';

export const updateName = (text) => ({
  type: MAIN_PAGE_NAME_UPDATE,
  text,
});
