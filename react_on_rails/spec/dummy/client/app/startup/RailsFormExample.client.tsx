// Dummy-app example for the useRailsForm hook (issue #3872).
//
// Submits to ContactMessagesController#create — a plain Rails action using the
// opt-in ReactOnRails::Controller::FormResponders concern. Submitting invalid
// data round-trips a 422 `{ errors: { field: [messages] } }` response into the
// per-field error messages rendered below each input.
import React from 'react';
import { useRailsForm } from 'react-on-rails/useRailsForm';

function FieldErrors({ messages }: { messages: string[] | undefined }) {
  if (!messages || messages.length === 0) {
    return null;
  }
  return (
    <ul className="field-errors" style={{ color: 'red' }}>
      {messages.map((message) => (
        <li key={message}>{message}</li>
      ))}
    </ul>
  );
}

export default function RailsFormExample() {
  const form = useRailsForm({ name: '', email: '', message: '' });
  const [successMessage, setSuccessMessage] = React.useState<string | null>(null);

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSuccessMessage(null);
    void form
      .post('/contact_messages', {
        onSuccess: (result) => {
          const body = result.responseData as { message?: string } | null;
          setSuccessMessage(body?.message ?? 'Submitted!');
          form.reset();
        },
      })
      .catch(() => {
        // Validation failures (422) are reported via form.errors; this catch
        // only handles unexpected statuses and network failures.
        form.setError('base', 'Something went wrong. Please try again.');
      });
  };

  return (
    <form onSubmit={handleSubmit} aria-busy={form.processing}>
      <h1>useRailsForm example</h1>
      {successMessage && <p className="success-message">{successMessage}</p>}
      <FieldErrors messages={form.errors.base} />
      <label htmlFor="contact-name">
        Name
        <input
          id="contact-name"
          name="name"
          value={form.data.name}
          onChange={(event) => form.setData('name', event.target.value)}
        />
      </label>
      <FieldErrors messages={form.errors.name} />
      <label htmlFor="contact-email">
        Email
        <input
          id="contact-email"
          name="email"
          value={form.data.email}
          onChange={(event) => form.setData('email', event.target.value)}
        />
      </label>
      <FieldErrors messages={form.errors.email} />
      <label htmlFor="contact-message">
        Message
        <textarea
          id="contact-message"
          name="message"
          value={form.data.message}
          onChange={(event) => form.setData('message', event.target.value)}
        />
      </label>
      <FieldErrors messages={form.errors.message} />
      <button type="submit" disabled={form.processing}>
        {form.processing ? 'Sending…' : 'Send'}
      </button>
    </form>
  );
}
