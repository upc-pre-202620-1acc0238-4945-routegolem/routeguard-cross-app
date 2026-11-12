enum PassengerBoardingStatus {
  pending,
  boarded,
  absent,
}

class DriverPassenger {
  final String id;
  final String name;
  final String grade;
  final String stopAddress;
  final String scheduledTime;
  PassengerBoardingStatus status;

  DriverPassenger({
    required this.id,
    required this.name,
    required this.grade,
    required this.stopAddress,
    required this.scheduledTime,
    this.status = PassengerBoardingStatus.pending,
  });

  static List<DriverPassenger> getInitialRoster() {
    return [
      DriverPassenger(
        id: 'p_01',
        name: 'Mateo Gómez',
        grade: 'Primaria • 4to B',
        stopAddress: 'Av. Brasil 1240, Jesús María',
        scheduledTime: '07:15 AM',
        status: PassengerBoardingStatus.boarded,
      ),
      DriverPassenger(
        id: 'p_02',
        name: 'Luciana Nery',
        grade: 'Primaria • 5to A',
        stopAddress: 'Calle Las Flores 302, Magdalena',
        scheduledTime: '07:22 AM',
        status: PassengerBoardingStatus.boarded,
      ),
      DriverPassenger(
        id: 'p_03',
        name: 'Jorge Salas',
        grade: 'Primaria • 3ro B',
        stopAddress: 'Av. Del Ejército 410, Miraflores',
        scheduledTime: '07:30 AM',
        status: PassengerBoardingStatus.pending,
      ),
      DriverPassenger(
        id: 'p_04',
        name: 'Andrea Solano',
        grade: 'Primaria • 6to A',
        stopAddress: 'Jr. Bolognesi 550, San Isidro',
        scheduledTime: '07:38 AM',
        status: PassengerBoardingStatus.pending,
      ),
      DriverPassenger(
        id: 'p_05',
        name: 'Matías Rey',
        grade: 'Primaria • 2do A',
        stopAddress: 'Av. San Martín 820, Pueblo Libre',
        scheduledTime: '07:45 AM',
        status: PassengerBoardingStatus.absent,
      ),
    ];
  }
}
