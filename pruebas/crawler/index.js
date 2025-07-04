const axios = require('axios');
const cheerio = require('cheerio');
const path = require('path');

const baseURL = 'http://192.168.1.90/.hidden/';

const visited = new Set();

async function crawl(url) {
    if (visited.has(url)) {
        return;
    }

    visited.add(url);

    try {
        const res = await axios.get(url);
        const $ = cheerio.load(res.data);

        const links = $('a')
            .map((_, a) => $(a).attr('href'))
            .get()
            .filter(href => href && href !== '../');

        for (const link of links) {
             const fullURL = new URL(link, url).href;

             if (link === 'README') {
                 try {
                     const readmeRes = await axios.get(fullURL, { responseType: 'text' });
                     console.log(readmeRes.data.trim());
                 } catch (err) {
                     console.warn(err, `❌ Failed to read README at ${fullURL}`);
                 }
             }
             else {
                 await crawl(fullURL);
             }
        }
    } catch (err) {
        console.error(`❌ Error fetching ${url}: ${err.message}`);
    }
}

(async () => {
    await crawl(baseURL);
})();

