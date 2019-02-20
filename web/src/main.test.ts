import { init } from "./main";

declare function setImmediate(cb: () => void): void;
const immediate = (): Promise<void> => new Promise((resolve) => setImmediate(resolve));

function getButton(name: string, buttons: HTMLButtonElement[]): HTMLButtonElement
{
    const button = buttons.find((e) => e.textContent === name);
    if (!button) {
        throw `Found no button '${name}'`;
    }
    return button;
}

describe("main", () => {
    beforeAll(() => {
        window.fetch = jest.fn(() => Promise.resolve({ok: true})) as any;
    });

    describe("click", () => {
        let on: HTMLButtonElement;
        let off: HTMLButtonElement;

        beforeEach(() => {
            if (document.body.firstChild !== null) {
                document.body.removeChild(document.body.firstChild);
            }
            jest.clearAllMocks();
            init("func.azurewebsites.net", "abc", "key");
            const buttons = Array.from(document.body.querySelectorAll("button"));
            on = getButton("An", buttons);
            off = getButton("Aus", buttons);
        });

        test("renders two buttons", () => {
            expect(document.body.querySelectorAll("button")).toHaveLength(2);
        });

        test("send request after on click", async () => {
            on.click();
            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Schalte Maschine an");
            await immediate();

            expect(window.fetch)
                .toHaveBeenCalledWith(expect.stringContaining("azurewebsites.net/api/switch?on"), {method: "POST"});
            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Maschine an");
        });

        test("send request after off click", async () => {
            off.click();
            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Schalte Maschine aus");
            await immediate();

            expect(window.fetch)
                .toHaveBeenCalledWith(expect.stringContaining("azurewebsites.net/api/switch?off"), {method: "POST"});
            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Maschine aus");
        });

        test("show error if request after on click fails on network error", async () => {
            window.fetch = jest.fn(() => { throw new Error("fetch faild"); });

            on.click();
            await immediate();

            expect((document.getElementById("status") as HTMLSpanElement).textContent)
                .toBe(`Netzwerkfehler: fetch faild`);
        });

        test("show error if request after on click is not ok", async () => {
            window.fetch = jest.fn(() => Promise.resolve({ok: false, text: () => Promise.resolve("Not working")})) as any;

            on.click();
            await immediate();

            expect((document.getElementById("status") as HTMLSpanElement).textContent)
                .toBe("Fehler vom Service: Not working");
        });
    });

    describe("warmup", () => {
        test("warms the function app on page load", async () => {
            init("func.azurewebsites.net", "abc", "key");
            expect(window.fetch).toHaveBeenCalledWith(expect.stringMatching(".azurewebsites.net/api/switch*$"));
            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Aufwärmen...");

            await immediate();

            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Aufgewärmt");
        });

        test("shows an error if warm up fails", async () => {
            window.fetch = jest.fn(() => { throw new Error("fetch faild"); });

            init("func.azurewebsites.net", "abc", "key");

            await immediate();

            expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Fehler beim Aufwärmen");
        });
    });
});
