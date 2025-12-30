const fs = require('fs');
const path = require('path');

// Simple markdown to HTML converter (no external dependencies)
function markdownToHTML(markdown) {
  let html = markdown;
  
  // Remove front matter
  html = html.replace(/^---[\s\S]*?---\s*/m, '');
  
  // Headers
  html = html.replace(/^### (.*$)/gim, '<h3>$1</h3>');
  html = html.replace(/^## (.*$)/gim, '<h2>$1</h2>');
  html = html.replace(/^# (.*$)/gim, '<h1>$1</h1>');
  
  // Code blocks (must be before inline code)
  html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, (match, lang, code) => {
    return `<pre><code>${escapeHtml(code.trim())}</code></pre>`;
  });
  
  // Inline code
  html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
  
  // Bold
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
  
  // Italic
  html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
  
  // Links
  html = html.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2">$1</a>');
  
  // Horizontal rules
  html = html.replace(/^---$/gm, '<hr>');
  
  // Tables
  html = html.replace(/\|(.+)\|/g, (match, row) => {
    if (row.includes('---')) {
      return ''; // Skip separator rows
    }
    const cells = row.split('|').map(cell => cell.trim()).filter(cell => cell);
    return '<tr>' + cells.map(cell => `<td>${cell}</td>`).join('') + '</tr>';
  });
  
  // Wrap table rows in table tags
  html = html.replace(/(<tr>[\s\S]*?<\/tr>\s*)+/g, (match) => {
    // Check if it's already in a table
    if (!match.includes('<table>')) {
      return '<table>' + match + '</table>';
    }
    return match;
  });
  
  // Add table headers (first row after table start)
  html = html.replace(/<table>\s*<tr>(.*?)<\/tr>/g, (match, cells) => {
    const cellContent = cells.replace(/<td>/g, '<th>').replace(/<\/td>/g, '</th>');
    return '<table><thead><tr>' + cellContent + '</tr></thead><tbody>';
  });
  html = html.replace(/<\/table>/g, '</tbody></table>');
  
  // Lists
  html = html.replace(/^\- (.+)$/gm, '<li>$1</li>');
  html = html.replace(/^(\d+)\. (.+)$/gm, '<li>$2</li>');
  
  // Wrap consecutive list items
  html = html.replace(/(<li>.*?<\/li>\s*)+/g, (match) => {
    if (!match.includes('<ul>')) {
      return '<ul>' + match + '</ul>';
    }
    return match;
  });
  
  // Blockquotes
  html = html.replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>');
  
  // Paragraphs (lines that don't start with HTML tags)
  html = html.split('\n').map(line => {
    const trimmed = line.trim();
    if (!trimmed || 
        trimmed.startsWith('<') || 
        trimmed.startsWith('#') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('|') ||
        trimmed.startsWith('>') ||
        trimmed.startsWith('```') ||
        /^\d+\./.test(trimmed)) {
      return line;
    }
    return `<p>${trimmed}</p>`;
  }).join('\n');
  
  // Clean up multiple empty lines
  html = html.replace(/\n{3,}/g, '\n\n');
  
  return html;
}

function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}

const htmlTemplate = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{TITLE} - PersistenceAI Documentation</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        :root {
            --bg-primary: #0d1117;
            --bg-secondary: #161b22;
            --text-primary: #d4d4d4;
            --text-secondary: #858585;
            --accent: #4ec9b0;
            --border: #3e3e3e;
            --code-bg: #161b22;
            --code-border: #30363d;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            padding: 2rem;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 2rem;
            color: var(--text-secondary);
            text-decoration: none;
        }
        .back-link:hover {
            color: var(--accent);
        }
        h1 {
            color: var(--accent);
            margin-bottom: 1.5rem;
            font-size: 2.5rem;
            border-bottom: 2px solid var(--border);
            padding-bottom: 1rem;
        }
        h2 {
            color: var(--accent);
            margin-top: 2rem;
            margin-bottom: 1rem;
            font-size: 1.75rem;
        }
        h3 {
            color: var(--text-primary);
            margin-top: 1.5rem;
            margin-bottom: 0.75rem;
            font-size: 1.25rem;
        }
        p {
            margin-bottom: 1rem;
            color: var(--text-primary);
        }
        ul, ol {
            margin-left: 2rem;
            margin-bottom: 1rem;
        }
        li {
            margin-bottom: 0.5rem;
            color: var(--text-primary);
        }
        code {
            background: var(--code-bg);
            border: 1px solid var(--code-border);
            border-radius: 4px;
            padding: 0.2rem 0.4rem;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
            color: var(--accent);
        }
        pre {
            background: var(--code-bg);
            border: 1px solid var(--code-border);
            border-radius: 8px;
            padding: 1rem;
            overflow-x: auto;
            margin-bottom: 1rem;
        }
        pre code {
            background: none;
            border: none;
            padding: 0;
            color: var(--text-primary);
            white-space: pre;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1.5rem;
        }
        th, td {
            border: 1px solid var(--border);
            padding: 0.75rem;
            text-align: left;
        }
        th {
            background: var(--bg-secondary);
            color: var(--accent);
            font-weight: 600;
        }
        td {
            color: var(--text-primary);
        }
        a {
            color: var(--accent);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        blockquote {
            border-left: 4px solid var(--accent);
            padding-left: 1rem;
            margin-left: 0;
            margin-bottom: 1rem;
            color: var(--text-secondary);
            font-style: italic;
        }
        hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 2rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <a href="index.html" class="back-link">← Back to Documentation</a>
        {CONTENT}
    </div>
</body>
</html>`;

const files = ['keybinds', 'commands', 'agents', 'providers', 'config', 'troubleshooting'];

files.forEach(file => {
  const mdFile = `${file}.md`;
  const htmlFile = `${file}.html`;
  
  if (fs.existsSync(mdFile)) {
    console.log(`Converting ${mdFile} to ${htmlFile}...`);
    
    const markdown = fs.readFileSync(mdFile, 'utf8');
    const htmlContent = markdownToHTML(markdown);
    
    // Extract title from first h1
    const titleMatch = htmlContent.match(/<h1>(.+?)<\/h1>/);
    const title = titleMatch ? titleMatch[1] : file;
    
    const finalHtml = htmlTemplate
      .replace('{TITLE}', title)
      .replace('{CONTENT}', htmlContent);
    
    fs.writeFileSync(htmlFile, finalHtml);
    console.log(`Created ${htmlFile}`);
  }
});

console.log('\nDone! All HTML files created.');
