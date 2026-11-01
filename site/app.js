// Only one excerpt plays at a time. Playback always requires a visitor action.
const players = [...document.querySelectorAll('audio')];
players.forEach(player => player.addEventListener('play', () => {
  players.forEach(other => { if (other !== player) other.pause(); });
}));
document.querySelector('#copy').addEventListener('click', async () => {
  const command = document.querySelector('#command').textContent;
  const status = document.querySelector('#copy-status');
  try {
    await navigator.clipboard.writeText(command);
    status.textContent = 'Copied. Run it from the repository folder.';
  } catch {
    status.textContent = 'Select and copy the command above.';
  }
});
// The publisher injects the repository URL from GitHub's workflow context.
// No personal account information is hard-coded in the page sources.
const repository = document.querySelector('meta[name="repository-url"]')?.content;
if (repository) {
  document.querySelectorAll('[data-repo-path]').forEach(link => {
    const path = link.dataset.repoPath;
    link.href = path ? `${repository}/blob/main/${path}` : repository;
  });
}
