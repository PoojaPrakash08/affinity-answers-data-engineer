
import requests
from bs4 import BeautifulSoup
from urllib.parse import urlencode, urljoin


BASE_URL = "https://mdcomputers.in/"


def scrape_products(search_term):
    """Fetch and extract products from MD Computers."""

    params = {
        "route": "product/search",
        "search": search_term
    }

    url = BASE_URL + "?" + urlencode(params)

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/130.0.0.0 Safari/537.36"
        ),
        "Accept": (
            "text/html,application/xhtml+xml,"
            "application/xml;q=0.9,*/*;q=0.8"
        ),
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": BASE_URL
    }

    try:
        response = requests.get(
            url,
            headers=headers,
            timeout=20
        )
        response.raise_for_status()

    except requests.RequestException as error:
        print(f"Could not fetch the page: {error}")
        return

    soup = BeautifulSoup(response.text, "html.parser")

    # Find product cards using the website's observed HTML structure.
    products = soup.select(".product-grid-item")

    print(f"\nHTTP Status: {response.status_code}")
    print(f"Products found on page: {len(products)}")

    results = []
    seen_links = set()

    for product in products:
        title_element = product.select_one(
            "h3.product-entities-title a"
        )

        if not title_element:
            continue

        name = title_element.get_text(" ", strip=True)
        href = title_element.get("href")

        if not name or not href:
            continue

        link = urljoin(response.url, href)

        if link in seen_links:
            continue

        seen_links.add(link)

        price_element = product.select_one(
            ".price"
        )

        price = (
            price_element.get_text(" ", strip=True)
            if price_element
            else "Not listed"
        )

        results.append({
            "name": name,
            "price": price,
            "link": link
        })

    if not results:
        print("No products were extracted.")
        print(
            "The page structure may have changed, "
            "or the search returned no extractable products."
        )
        print(f"Search page: {response.url}")
        return

    print(f"\nProducts matching: {search_term}")
    print("=" * 60)

    for number, item in enumerate(results, start=1):
        print(f"\nProduct {number}")
        print(f"Name : {item['name']}")
        print(f"Price: {item['price']}")
        print(f"Link : {item['link']}")

    print(f"\nTotal products extracted: {len(results)}")


if __name__ == "__main__":
    term = input("Enter a product search term: ").strip()

    if term:
        scrape_products(term)
    else:
        print("Please enter a valid search term.")