/**
 * The single source of truth for how a customer reaches a human.
 *
 * Every value here must be real and reachable. The footer, Help & Support and
 * the admin screens all read from this file — do not hard-code a phone number or
 * an address anywhere else, because a invented one silently dead-ends a hungry
 * customer. `info@tanzaniareach.com` is the monitored support mailbox.
 */
export const contact = {
  email: 'info@tanzaniareach.com',
  phoneDisplay: '+255 790 942 616',
  /** E.164 without separators — what `tel:` and `wa.me` require. */
  phoneE164: '+255790942616',
  whatsapp: '255790942616',
  hours: 'Every day · 08:00 – 22:00 EAT',
  city: 'Dar es Salaam, Tanzania',
  /** Where the kitchen and dispatch desk actually are. */
  kitchen: 'Kijitonyama, Kinondoni',
} as const;

export const contactLinks = {
  email: `mailto:${contact.email}`,
  phone: `tel:${contact.phoneE164}`,
  whatsapp: `https://wa.me/${contact.whatsapp}`,
} as const;

/** Pre-filled mail link, so a customer never has to compose from scratch. */
export function supportMailLink(subject: string, body?: string) {
  const params = new URLSearchParams({ subject });
  if (body) params.set('body', body);
  return `mailto:${contact.email}?${params.toString()}`;
}
