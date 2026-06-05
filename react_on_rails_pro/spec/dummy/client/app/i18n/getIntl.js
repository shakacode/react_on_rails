import { cache } from 'react';
import { createIntl } from '@formatjs/intl';
import messages from './messages';

const getIntl = cache((locale) => {
  return createIntl({
    locale,
    messages: messages[locale] || messages.en,
  });
});

export default getIntl;
