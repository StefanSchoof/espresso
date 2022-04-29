use funksteckdose::{error::Error, Device, Funksteckdose, Protocol1, State};

use crate::{encoding::MyEncoding, gpio_pin::GpioPin};

mod encoding;
mod gpio_pin;

#[macro_use]
extern crate rocket;

type MyFunk = Funksteckdose<GpioPin, MyEncoding, Protocol1>;
type Result = std::result::Result<(), rocket::response::Debug<Error>>;

fn send(steckdose: &MyFunk, state: &State) -> Result {
    steckdose.send("11001", &Device::A, state)?;
    Ok(())
}

#[post("/on")]
fn on(steckdose: &rocket::State<MyFunk>) -> Result {
    println!("on");
    send(steckdose, &State::On)
}

#[post("/off")]
fn off(steckdose: &rocket::State<MyFunk>) -> Result {
    println!("off");
    send(steckdose, &State::Off)
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
