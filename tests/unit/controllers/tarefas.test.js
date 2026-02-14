const tarefasController = require('../../../api/controllers/tarefas');

describe('Tarefas Controller', () => {
  test('deve exportar um controller com métodos corretos', () => {
    const controller = tarefasController();
    
    expect(typeof controller).toBe('object');
    expect(typeof controller.create).toBe('function');
    expect(typeof controller.findAll).toBe('function');
    expect(typeof controller.find).toBe('function');
    expect(typeof controller.delete).toBe('function');
    expect(typeof controller.update_priority).toBe('function');
  });
});
