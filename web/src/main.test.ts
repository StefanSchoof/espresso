import { init } from './main';

declare function setImmediate(cb: () => void): void;
const immediate = () => new Promise(resolve => setImmediate(resolve));

describe('main', ()=> {
    let on: HTMLButtonElement;
    let off: HTMLButtonElement;
    beforeAll(() => {
        init();
        on = Array.from(document.body.querySelectorAll('button') as NodeListOf<HTMLButtonElement>).find((e) => e.textContent === "An")!;
        off = Array.from(document.body.querySelectorAll('button') as NodeListOf<HTMLButtonElement>).find((e) => e.textContent === "Aus")!;
    });
    
    beforeEach(() => {
        jest.resetAllMocks();
        window.fetch = jest.fn(() => Promise.resolve({ok: true}));
    })

    test('renders two buttons', () => {
        expect(document.body.querySelectorAll('button')).toHaveLength(2);
    });
    
    test('send request after on click', async () => {
        on.click();
        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Schalte Maschine an");
        await immediate();

        expect(window.fetch).toHaveBeenCalledWith(expect.stringContaining("azurewebsites.net/api/switch?on"), {method: "POST"});
        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Maschine an");
    });

    test('send request after off click', async () => {
        off.click();
        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Schalte Maschine aus");
        await immediate();

        expect(window.fetch).toHaveBeenCalledWith(expect.stringContaining("azurewebsites.net/api/switch?off"), {method: "POST"});
        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Maschine aus");
    });

    test('show error if request after on click fails on network error', async () => {
        window.fetch = jest.fn(() => { throw new Error("fetch faild") });

        on.click();
        await immediate();

        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe(`Netzwerkfehler: fetch faild`);
    });

    test('show error if request after on click is not ok', async () => {
        window.fetch = jest.fn(() => Promise.resolve({ok: false, text: () => Promise.resolve("Not working")}));

        on.click();
        await immediate();

        expect((document.getElementById("status") as HTMLSpanElement).textContent).toBe("Fehler vom Service: Not working");
    });

    test('warms the function app on page load', async () => {
        expect(window.fetch).toHaveBeenCalledWith(expect.stringMatching('.azurewebsites.net/api/switch*$'));
    });
});