---
layout: blog
title: Blog
---

# Blog

Technical writings on platform engineering, distributed systems, and infrastructure.

---

{% if site.posts.size > 0 %}
<ul class="post-list">
{% for post in site.posts %}
<li>
    <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
    <div class="post-meta">{{ post.date | date: "%B %d, %Y" }}</div>
    <div class="excerpt">{{ post.excerpt }}</div>
</li>
{% endfor %}
</ul>
{% else %}
No blog posts yet. Check back soon!
{% endif %}
