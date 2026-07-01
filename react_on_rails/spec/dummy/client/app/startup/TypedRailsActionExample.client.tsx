import React from 'react';
import {
  createContactMessage,
  type ContactMessageFieldErrors,
  type ContactMessageFormValues,
  validationErrorsFromRailsAction,
} from '../actions/contactMessageActions';

const EMPTY_FORM: ContactMessageFormValues = {
  email: '',
  message: '',
  name: '',
};

function FieldErrors({ messages, id }: { messages: string[] | undefined; id?: string }) {
  if (!messages || messages.length === 0) {
    return null;
  }

  return (
    <ul id={id} className="field-errors" style={{ color: 'red' }}>
      {messages.map((message) => (
        <li key={message}>{message}</li>
      ))}
    </ul>
  );
}

export default function TypedRailsActionExample() {
  const [form, setForm] = React.useState<ContactMessageFormValues>(EMPTY_FORM);
  const [errors, setErrors] = React.useState<ContactMessageFieldErrors>({});
  const [processing, setProcessing] = React.useState(false);
  const [successMessage, setSuccessMessage] = React.useState<string | null>(null);

  const setField = (field: keyof ContactMessageFormValues, value: string) => {
    setForm((currentForm) => ({ ...currentForm, [field]: value }));
  };

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setProcessing(true);
    setErrors({});
    setSuccessMessage(null);

    try {
      const response = await createContactMessage(form);
      setSuccessMessage(response.message);
      setForm(EMPTY_FORM);
    } catch (error) {
      const validationErrors = validationErrorsFromRailsAction(error);
      setErrors(validationErrors ?? { base: ['Something went wrong. Please try again.'] });
    } finally {
      setProcessing(false);
    }
  };

  return (
    <form
      onSubmit={(event) => {
        void handleSubmit(event);
      }}
      aria-busy={processing}
    >
      <h1>Typed Rails action example</h1>
      {successMessage && <p className="success-message">{successMessage}</p>}
      <FieldErrors messages={errors.base} />
      <label htmlFor="typed-contact-name">
        Name
        <input
          id="typed-contact-name"
          name="name"
          value={form.name}
          onChange={(event) => setField('name', event.target.value)}
          aria-describedby={errors.name ? 'typed-contact-name-errors' : undefined}
          aria-invalid={errors.name ? true : undefined}
        />
      </label>
      <FieldErrors id="typed-contact-name-errors" messages={errors.name} />
      <label htmlFor="typed-contact-email">
        Email
        <input
          id="typed-contact-email"
          name="email"
          value={form.email}
          onChange={(event) => setField('email', event.target.value)}
          aria-describedby={errors.email ? 'typed-contact-email-errors' : undefined}
          aria-invalid={errors.email ? true : undefined}
        />
      </label>
      <FieldErrors id="typed-contact-email-errors" messages={errors.email} />
      <label htmlFor="typed-contact-message">
        Message
        <textarea
          id="typed-contact-message"
          name="message"
          value={form.message}
          onChange={(event) => setField('message', event.target.value)}
          aria-describedby={errors.message ? 'typed-contact-message-errors' : undefined}
          aria-invalid={errors.message ? true : undefined}
        />
      </label>
      <FieldErrors id="typed-contact-message-errors" messages={errors.message} />
      <button type="submit" disabled={processing}>
        {processing ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
