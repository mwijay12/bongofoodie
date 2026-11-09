'use client';

import { useEffect, useState } from 'react';
import { ArrowRight, Check, X } from 'lucide-react';
import styles from '@/app/home.module.css';

const questions = [
  { question: "Which spice is called ‘Mdalasini’?", options: ['Clove', 'Cinnamon', 'Cardamom', 'Ginger'], correct: 1, explanation: 'Mdalasini is cinnamon. Its bark adds a warm aroma to Swahili chai and pilau.' },
  { question: 'What does ‘Tui la Nazi’ mean?', options: ['Coconut milk', 'Cow milk', 'Peanut paste', 'Mango juice'], correct: 0, explanation: 'Tui la Nazi is coconut milk, used in coastal rice dishes, curries and beans.' },
  { question: 'What are Tanzanian mishkaki?', options: ['Beef skewers', 'Potato omelette', 'Spiced rice', 'Coconut beans'], correct: 0, explanation: 'Mishkaki are marinated pieces of meat threaded onto skewers and grilled over charcoal.' },
];

export default function SwahiliTrivia() {
  const [day, setDay] = useState(0);
  const [answer, setAnswer] = useState<number | null>(null);
  const [dismissed, setDismissed] = useState(false);
  useEffect(() => {
    const timer = window.setTimeout(() => setDay(new Date().getDay() % questions.length), 0);
    return () => window.clearTimeout(timer);
  }, []);
  const quiz = questions[day];
  if (dismissed) return null;
  return (
    <section className={styles.trivia} aria-labelledby="trivia-title">
      <div>
        <p className={styles.eyebrow}>A little coastal knowledge</p>
        <h2 id="trivia-title">Know your spices?</h2>
        <p>One question. Something to talk about over lunch.</p>
      </div>
      <div>
        <h3>{quiz.question}</h3>
        <div className={styles.answers}>
          {quiz.options.map((option, index) => (
            <button key={option} disabled={answer !== null} onClick={() => setAnswer(index)}
              data-result={answer !== null && index === quiz.correct ? 'correct' : answer === index ? 'incorrect' : undefined}>
              <span>{option}</span>
              {answer !== null && index === quiz.correct && <Check size={18} aria-label="Correct answer" />}
              {answer === index && index !== quiz.correct && <X size={18} aria-label="Your answer was incorrect" />}
            </button>
          ))}
        </div>
        {answer !== null && (
          <div className={styles.quizResult} role="status">
            <strong>{answer === quiz.correct ? 'Correct. ' : 'Not quite. '}</strong>{quiz.explanation}
            {answer === quiz.correct && <p>Use KARIBU2000 at checkout for TSh 2,000 off.</p>}
            <button onClick={() => setDismissed(true)}>Got it <ArrowRight size={16} aria-hidden="true" /></button>
          </div>
        )}
      </div>
    </section>
  );
}
