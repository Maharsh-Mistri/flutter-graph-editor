# Flutter Interactive Graph Editor 🌳

![App Demo GIF](demo.gif)

> A dynamic and interactive graph and tree visualization application built with Flutter. This app allows users to create, manipulate, and explore tree data structures in real-time on a zoomable and pannable canvas.

---

## ✨ Key Features

* **Dynamic Graph Visualization:** Nodes and edges are laid out automatically using the Buchheim-Walker algorithm from the `graphview` package.
* **Smart Node ID Assignment:** Intelligently finds and reuses the smallest available integer ID for new nodes. If you delete node #3, the next node created will become the new #3.
* **Interactive Canvas:**
    * **Pan:** Click-and-drag or use the mouse scroll wheel to move around the canvas.
    * **Zoom:** Use a two-finger pinch gesture on a trackpad or touchscreen.
* **Full Node Manipulation:**
    * **Add Child Nodes:** Select any node and add children to it.
    * **Delete Nodes:** Delete any node (and its entire subtree) using the button or the 'X' icon.
    * **Reset Tree:** Deleting the root node cleanly resets the entire tree.
* **Real-time Info Display:** The app bar always shows the current maximum depth of the tree.
* **Reset View:** If you get lost on the canvas, a dedicated button instantly re-centers the view.
* **User-Friendly Feedback:** The app provides clear error messages using Snackbars for invalid actions.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/)
* **Language:** [Dart](https://dart.dev/)
* **Core Package:** [graphview](https://pub.dev/packages/graphview) for tree layout and rendering.

---

## 🚀 Getting Started

To run this project locally, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YOUR_USERNAME/flutter-graph-editor.git](https://github.com/YOUR_USERNAME/flutter-graph-editor.git)
    cd flutter-graph-editor
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Enable desktop support (if needed):**
    ```bash
    flutter config --enable-windows-desktop
    # or --enable-macos-desktop / --enable-linux-desktop
    ```

4.  **Run the application:**
    ```bash
    flutter run
    ```

---

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.
