use funksteckdose::{Device, Funksteckdose, Protocol1, State};

use crate::{encoding::MyEncoding, gpio_pin::GpioPin};

mod encoding;
mod gpio_pin;

#[macro_use]
extern crate rocket;

type MyFunk = Funksteckdose<GpioPin, MyEncoding, Protocol1>;

fn send(steckdose: &MyFunk, state: &State) {
    steckdose
        .send("11001", &Device::A, state)
        .expect("Failed to send");
}

#[post("/on")]
fn on(steckdose: &rocket::State<MyFunk>) {
    println!("on");
    send(&steckdose, &State::On)
}

#[post("/off")]
fn off(steckdose: &rocket::State<MyFunk>) {
    println!("off");
    send(&steckdose, &State::Off)
}

#[get("/health")]
fn health() -> &'static str {
    "OK"
}

#[launch]
fn rocket() -> _ {
    let pin = GpioPin::new(17).expect("Failed to setup gpio pin");
    let steckdose = MyFunk::new(pin);
    rocket::build()
        .manage(steckdose)
        .mount("/api", routes![on, off, health])
}
