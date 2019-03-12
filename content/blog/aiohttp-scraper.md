+++
title = "Mejorando los scrapers con aiohttp"
date = 2019-03-06T14:20:47-05:00
tags = ["python","scraper","asyncio","aiohttp"]
categories = [""]
draft = true
description = "Creando scrapers con aiohttp"
+++

¿Adivinan que está mal con este código?

```python
async def get(url):
    async with session.get(url) as response:
        return await response.read()

async def get_data(url):
    async with ClientSession() as session:
        result = await get(url)
        process_data(result)
        next_page = get_next_page(result)
        await get_data(url)
```

A simple vista parece un scraper sencillo
