import { createRailsAction, RailsActionRequestError } from 'react-on-rails/railsAction';
import type { RailsResponseType } from '../types/react_on_rails_response_types';

export type ContactMessageFormValues = {
  email: string;
  message: string;
  name: string;
};

type ContactMessageCreateResponse = RailsResponseType<'contact_messages.create'>;
type ContactMessageValidationErrorResponse = RailsResponseType<'contact_messages.validation_error'>;

export type ContactMessageFieldErrors = ContactMessageValidationErrorResponse['errors'];

export const createContactMessage = createRailsAction<ContactMessageFormValues, ContactMessageCreateResponse>(
  {
    path: '/contact_messages',
  },
);

export const validationErrorsFromRailsAction = (error: unknown): ContactMessageFieldErrors | null => {
  if (!(error instanceof RailsActionRequestError) || error.response.status !== 422) {
    return null;
  }

  const responseBody = error.responseBody as Partial<ContactMessageValidationErrorResponse> | null;
  return responseBody?.errors ?? null;
};
