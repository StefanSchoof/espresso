export function init(): void {
  async function send(arg: string, title: string): Promise<void> {
    const status = document.getElementById("status");
    if (status == null) {
      throw new Error("Could not find status");
    }
    status.textContent = `Schalte Maschine ${title.toLocaleLowerCase()}`;
    try {
      const res = await fetch(`api/${arg}`, { method: "POST" });
      status.textContent = res.ok
        ? `Maschine ${title.toLocaleLowerCase()}`
        : `Fehler vom Service: ${await res.text()}`;
    } catch (err) {
      status.textContent =
        err instanceof Error
          ? `Netzwerkfehler: ${err.message}`
          : `Unbekannter Fehler: ${JSON.stringify(err)}`;
    }
  }

  function createButton(arg: "on" | "off", title: string): HTMLButtonElement {
    const button = document.createElement("button");
    button.style.height = "100px";
    button.style.width = "200px";
    button.style.fontSize = "60px";
    button.textContent = title;
    button.addEventListener("click", (): void => {
      send(arg, title).catch(() => {});
    });
    return button;
  }

  function component(): HTMLDivElement {
    const div = document.createElement("div");
    div.appendChild(createButton("on", "An"));
    div.appendChild(document.createElement("br"));
    div.appendChild(createButton("off", "Aus"));
    div.appendChild(document.createElement("br"));
    const span = document.createElement("span");
    span.id = "status";
    div.appendChild(span);

    return div;
  }

  document.body.appendChild(component());
}
