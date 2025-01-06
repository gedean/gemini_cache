# GeminiCache Module Usage Documentation

## Introduction
The `GeminiCache` module is a library designed for managing API caches, with features to process web pages, local and remote files, as well as interact with an API to create, update, list, and delete caches. This document describes its functionalities and usage.

## Requirements
To use the module, ensure the following Ruby libraries are installed:

- `faraday`
- `open-uri`
- `nokogiri`
- `json`
- `base64`

## Code Structure

The module includes the following components:

1. **Classes and Modules**:
   - `GeminiCache::Error`: Class for handling custom errors.
   - `GeminiCache`: Contains the main methods for cache management and file processing.

2. **Dependencies**:
   - `gemini_cache/configuration`
   - `gemini_cache/api_client`
   - `gemini_cache/item_extender`

## Features

### 1. HTML Parsing
Allows processing and cleaning the content of a web page.

#### Syntax
```ruby
GeminiCache.parse_html(url:, default_remover: true)
```
- **Parameters**:
  - `url`: The URL of the page to process.
  - `default_remover`: Automatically removes `<script>` and `<style>` elements (default: `true`).
- **Returns**: A `Nokogiri::HTML` object containing the processed HTML.

### 2. File Reading

#### a) Local Files
Reads a local file and returns its Base64 encoded data.
```ruby
GeminiCache.read_local_file(path:, mime_type:)
```
- **Parameters**:
  - `path`: Path to the file.
  - `mime_type`: MIME type of the file.
- **Returns**: Hash containing the encoded data.

#### b) Remote Files
Reads a remote file and returns its Base64 encoded data.
```ruby
GeminiCache.read_remote_file(url:, mime_type:)
```
- **Parameters**:
  - `url`: URL of the file.
  - `mime_type`: MIME type of the file.
- **Returns**: Hash containing the encoded data.

### 3. Webpage Text Reading
Extracts text content from a web page, removing unnecessary elements.
```ruby
GeminiCache.read_webpage_text(url:, default_remover: true)
```
- **Parameters**:
  - `url`: URL of the page.
  - `default_remover`: Automatically removes `<script>` and `<style>` elements (default: `true`).
- **Returns**: Hash containing the page text.

### 4. Cache Creation
Creates a new cache from different data sources.

#### General Syntax
```ruby
GeminiCache.create(parts:, display_name:, on_conflict: :raise_error, model: nil, ttl: nil)
```
- **Parameters**:
  - `parts`: Cache data.
  - `display_name`: Display name of the cache.
  - `on_conflict`: Action on conflict (`:raise_error` or `:get_existing`).
  - `model`: Model used (default: system configuration).
  - `ttl`: Time-to-live for the cache (default: system configuration).
- **Returns**: The created cache object.

#### Creation Methods
- Text:
  ```ruby
  GeminiCache.create_from_text(text:, **options)
  ```
- Web Page:
  ```ruby
  GeminiCache.create_from_webpage(url:, **options)
  ```
- Local File:
  ```ruby
  GeminiCache.create_from_local_file(path:, mime_type:, **options)
  ```
- Remote File:
  ```ruby
  GeminiCache.create_from_remote_file(url:, mime_type:, **options)
  ```

### 5. Cache Management

#### Cache Listing
Lists all available caches.
```ruby
GeminiCache.list
```
- **Returns**: Array of cache objects.

#### Cache Retrieval
- By Name:
  ```ruby
  GeminiCache.find_by_name(name:)
  ```
- By Display Name:
  ```ruby
  GeminiCache.find_by_display_name(display_name:)
  ```

#### Cache Updating
Updates an existing cache.
```ruby
GeminiCache.update(name:, content:)
```
- **Parameters**:
  - `name`: Name of the cache.
  - `content`: Updated content.

#### Cache Deletion
- By Name:
  ```ruby
  GeminiCache.delete(name:)
  ```
- All Caches:
  ```ruby
  GeminiCache.delete_all
  ```

## Configuration
The methods use configurations defined in the `gemini_cache/configuration` module, and communication is handled via `gemini_cache/api_client`.

## Errors
In case of conflicts or API errors, the module raises a custom exception `GeminiCache::Error`.

## Conclusion
This documentation covers the main functionalities of the `GeminiCache` module. For more details on specific configurations, refer to the source code or official documentation.

