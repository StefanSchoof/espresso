use funksteckdose::{Device, Funksteckdose, Protocol1, State};

use crate::{encoding::MyEncoding, gpio_pin::GpioPin};

mod encoding;
mod gpio_pin;

#[macro_use]
extern crate rocket;

type MyFunk = Funksteckdose<GpioPin, MyEncoding, Protocol1>;

fn send(state: &State) {
    let pin = GpioPin::new(17).expect("Failed to setup");
    let steckdose = MyFunk::new(pin);
    steckdose
        .send("11001", &Device::A, state)
        .expect("Failed to send");
}

#[post("/on")]
fn on() {
    println!("on");
    send(&State::On)
}

#[post("/off")]
fn off() {
    println!("off");
    send(&State::Off)
}

#[get("/health")]
fn health() -> &'static str {
    "OK"
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/api", routes![on, off, health])
}

