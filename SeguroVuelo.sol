
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SeguroVuelo {
    address public administrador;

    struct Seguro {
        address payable pasajero;
        uint256 compensacion;
        bool activo;
        bool pagado;
    }

    mapping(string => Seguro) public seguros;

    event SeguroRegistrado(string codigoVuelo, address pasajero);
    event CompensacionPagada(string codigoVuelo, address pasajero, uint256 monto);

    modifier soloAdministrador() {
        require(msg.sender == administrador, "Solo el administrador");
        _;
    }

    constructor() {
        administrador = msg.sender;
    }

    function registrarSeguro(
        string memory codigoVuelo,
        address payable pasajero,
        uint256 compensacion
    ) public soloAdministrador {
        require(bytes(codigoVuelo).length > 0, "Codigo vacio");
        require(pasajero != address(0), "Pasajero invalido");
        require(compensacion > 0, "Compensacion invalida");
        require(!seguros[codigoVuelo].activo, "Seguro activo");

        seguros[codigoVuelo] = Seguro({
            pasajero: pasajero,
            compensacion: compensacion,
            activo: true,
            pagado: false
        });

        emit SeguroRegistrado(codigoVuelo, pasajero);
    }

    function depositarFondos() public payable soloAdministrador {
        require(msg.value > 0, "Debe depositar ETH");
    }

    function verificarRetraso(
        string memory codigoVuelo,
        uint256 minutosRetraso
    ) public soloAdministrador {
        Seguro storage seguro = seguros[codigoVuelo];

        require(seguro.activo, "Seguro inexistente o inactivo");
        require(!seguro.pagado, "Ya fue pagado");
        require(minutosRetraso >= 120, "Retraso menor a 120 minutos");
        require(address(this).balance >= seguro.compensacion, "Fondos insuficientes");

        seguro.pagado = true;
        seguro.activo = false;

        (bool exito, ) = seguro.pasajero.call{value: seguro.compensacion}("");
        require(exito, "Fallo el pago");

        emit CompensacionPagada(codigoVuelo, seguro.pasajero, seguro.compensacion);
    }

    function consultarSaldo() public view returns (uint256) {
        return address(this).balance;
    }
}
