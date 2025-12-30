# Logo Display Guide

## How Companies Display Logos

Companies typically display logos in navigation bars using one of these methods:

### Method 1: Image Tag (Recommended)
```html
<a href="#" class="logo">
    <img src="logo.png" alt="Company Name" />
    Company Name
</a>
```

**Pros:**
- Simple and reliable
- Works in all browsers
- Easy to control size
- Can be cached by browser

### Method 2: CSS Background Image
```css
.logo::before {
    content: '';
    display: inline-block;
    width: 1.5rem;
    height: 1.5rem;
    background-image: url('logo.png');
    background-size: contain;
}
```

**Pros:**
- No HTML changes needed
- Can be styled with CSS
- Good for icons

**Cons:**
- Less semantic
- Harder to debug if image doesn't load

### Method 3: SVG Inline
```html
<a href="#" class="logo">
    <svg width="24" height="24">...</svg>
    Company Name
</a>
```

**Pros:**
- Scalable (vector)
- Can be styled with CSS
- No separate image file

### Method 4: Icon Font
```html
<a href="#" class="logo">
    <i class="icon-logo"></i>
    Company Name
</a>
```

**Pros:**
- Very lightweight
- Easy to color/style
- Scales perfectly

## Current Implementation

We're using **Method 1 (Image Tag)** which is the most reliable approach.

## Logo File Location

- **File:** `website/logo.png`
- **Path in HTML:** `src="logo.png"` (relative to index.html)
- **Size:** 1.5rem × 1.5rem (~24px × 24px)

## Troubleshooting

If logo doesn't show:

1. **Check file exists:** `website/logo.png`
2. **Check path:** Should be same folder as `index.html`
3. **Check browser console:** Look for 404 errors
4. **Try absolute path:** `/logo.png` or `./logo.png`
5. **Check file permissions:** File should be readable

## Best Practices

1. **Use SVG for logos** when possible (scalable, small file size)
2. **Optimize PNG/JPEG** images (compress, use appropriate dimensions)
3. **Provide alt text** for accessibility
4. **Use appropriate sizes:**
   - Navigation bar: 24-32px height
   - Favicon: 16×16 or 32×32px
   - Hero section: Larger (48-64px)

## Converting to SVG (Optional)

For best results, convert your logo to SVG:
1. Better scalability
2. Smaller file size
3. Can be styled with CSS
4. Works at any resolution
