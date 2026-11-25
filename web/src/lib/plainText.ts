/**
 * Clean an AI reply so it reads as plain conversational text.
 *
 * The Chef AI models occasionally wrap words in markdown emphasis
 * (`**bold**`, `*italic*`, `_x_`, backticks, `###` headings). We render
 * replies as plain text, so those markers leaked into the bubbles as
 * literal asterisks. This strips them while leaving the words intact.
 *
 * Deliberately conservative: it only removes syntax that cannot occur in
 * normal Swahili or English prose, and it never deletes content.
 */
export function stripMarkdown(input: string): string {
  if (!input) return '';

  let text = input;

  // Code fences and inline code.
  text = text.replace(/```[a-zA-Z]*\n?/g, '');
  text = text.replace(/`([^`]+)`/g, '$1');

  // Emphasis: run the longest markers first so *** and ** do not leave a
  // stray asterisk behind.
  text = text.replace(/\*{3,}([^*\n]+)\*{3,}/g, '$1');
  text = text.replace(/\*{2,}([^*\n]+)\*{2,}/g, '$1');
  text = text.replace(/_{2,}([^_\n]+)_{2,}/g, '$1');
  text = text.replace(/(^|[\s(])\*([^*\n]+)\*(?=[\s).,!?:;]|$)/g, '$1$2');
  text = text.replace(/(^|[\s(])_([^_\n]+)_(?=[\s).,!?:;]|$)/g, '$1$2');

  // Any asterisk left over is decoration, not content.
  text = text.replace(/\*/g, '');

  // Headings ("### Title") become plain lines.
  text = text.replace(/^#{1,6}\s+/gm, '');

  // Blockquote markers.
  text = text.replace(/^>\s?/gm, '');

  // Markdown links keep their label only.
  text = text.replace(/\[([^\]]+)\]\([^)]*\)/g, '$1');

  // Horizontal rules.
  text = text.replace(/^\s*[-_]{3,}\s*$/gm, '');

  // Bullet markers become a simple dash, which reads fine in a bubble.
  text = text.replace(/^\s*[-+]\s+/gm, '• ');

  // Collapse the blank lines the removed block syntax leaves behind.
  text = text.replace(/[ \t]+$/gm, '');
  text = text.replace(/\n{3,}/g, '\n\n');

  return text.trim();
}
