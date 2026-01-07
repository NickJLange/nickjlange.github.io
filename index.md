---
layout: default
title: Home
---

<header>
    <h1>Nick J. Lange</h1>
    <p class="headline">Technologist</p>
    <p>New York</p>
    <div class="links">
        <a href="https://github.com/NickJLange">GitHub</a>
        <a href="https://linkedin.com/in/NickLange">LinkedIn</a>
        <a href="mailto:jobs@wafuu.design">Contact</a>
        <a href="/assets/resume.html">CV</a>
    </div>
</header>


<section>
    <h2>What I'm Working On</h2>
    {% if site.posts.size > 0 %}
        {% for post in site.posts limit:5 %}
        <div class="card">
            <h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
            <p class="date">{{ post.date | date: "%B %d, %Y" }}</p>
            <p>{{ post.excerpt }}</p>
        </div>
        {% endfor %}
        <a href="/blog">View all posts →</a>
    {% else %}
    <div class="card">
        <p class="blog-placeholder">Blog posts coming soon...</p>
    </div>
    {% endif %}
</section>

<section>
    <h2>About</h2>
    <div class="card">
        <p>This place is not intended, marketed, or affiliated with any company or organization. Content is purely focused on Technology</p> 
        <p> Please see my CV and hyperlinks to the respective organizations for appropriately stated commentary.</p>
    </div>
</section>

<footer>
    <p>&copy; 2026 Nick J. Lange</p>
</footer>
