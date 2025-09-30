# 📄 PDF → Markdown Converter

A **deep learning–powered PDF-to-Markdown conversion pipeline**, engineered to handle both **digitally generated PDFs** and **scanned image-based PDFs** with remarkable accuracy. This project combines **OCR, table parsing, layout analysis, and containerized multi-framework deployment** into a unified workflow.

> Built in Sept 2025 to explore **cross-framework integration**, **document AI**, and **full-stack Python development**.

---

## ✨ Features

* **📑 Dual PDF Support**

  * **Digital PDFs**: Extracts text & tables via `Marker` + `Camelot`/`pdfplumber`.
  * **Scanned PDFs**: Applies `PaddleOCR` + `PP-StructureV2` to parse multilingual text, tables, formulas, indexes, and diagrams.

* **🔬 Structural Markdown Generation**

  * Reconstructs **tables, math formulas, footnotes, and schematic parts** in Markdown.
  * Preserves layout integrity for complex academic and technical documents.

* **⚡ Cross-Framework Isolation**

  * Solved dependency conflicts between **PyTorch** and **PaddlePaddle** using Docker containerization.
  * Built dedicated environments:

    * `pytorch:2.2.0-cuda12.1`
    * `paddlepaddle:2.6.0-gpu-cuda12.1`

* **🔗 Container-Orchestrated APIs**

  * Managed via `docker-compose`.
  * RESTful service layer coordinates inference tasks across both frameworks seamlessly.

* **⬇️ One-Click Markdown Export**

  * Users upload a PDF → system auto-detects type → delivers Markdown file for download.

---

## 🚀 Demo

| Digital PDF → MD            | Scanned PDF → MD            | Complex Layout Recovery        |
| --------------------------- | --------------------------- | ------------------------------ |
| ![demo1](docs/pdf_text.png) | ![demo2](docs/pdf_scan.png) | ![demo3](docs/pdf_complex.png) |

*(Screenshots/GIFs are placeholders — replace with your actual outputs!)*

---

## 🛠️ Tech Stack

* **Languages**: Python
* **Frameworks**: PyTorch, PaddlePaddle
* **Libraries**: `camelot`, `pdfplumber`, `PaddleOCR`, `PP-StructureV2`, `Marker`
* **Infrastructure**: Docker, docker-compose, RESTful API
* **Deployment**: GPU-enabled environments (CUDA 12.1)

---

## 📦 Installation

Clone and start with docker-compose:

```bash
git clone https://github.com/yourusername/pdf2md.git
cd pdf2md
docker compose up --build
```

Upload PDFs via the API endpoint:

```bash
curl -F "file=@sample.pdf" http://localhost:8000/convert
```

---

## 📈 Development Journey

* Designed end-to-end **document AI workflow** from OCR to Markdown serialization.
* Overcame **multi-framework dependency hell** with Docker-based microservices.
* Iteratively tuned OCR models for **multilingual (EN/CH) accuracy**.
